#include <inttypes.h>

typedef struct {
  float source;
  float target;
}wp_playerlib_fader_fade;

typedef struct {
  int32_t totalFrames;
  int32_t progressFrames:31; // packing things tight so this struct can be an atomic
  uint32_t atTargetInvoked:1;
} wp_playerlib_fader_progress;

typedef struct {
  ma_node_base base;
  _Atomic wp_playerlib_fader_fade fade;
  _Atomic wp_playerlib_fader_progress progress;
  void (*onTargetReached)(void* context);
  void* onTargetReachedContext;
} wp_playerlib_fader;

float fastSin(float x) {
    static const float c1 = 4.f / M_PI;
    static const float c2 = -4.f / (M_PI * M_PI);
    float y = x * ((fabsf(x) * c2) + c1);
    return 0.225f * (y * fabsf(y) - y) + y;
}

float faderProgressEased(float linearProgress) {
  float clamped = fmaxf(0.0f, fminf(1.0f, linearProgress));
  return (fastSin(clamped * M_PI - M_PI_2) + 1.0f) * 0.5f;
}

void wp_playerlib_fader_set_source_and_target_starting_at_frame(wp_playerlib_fader* pFader, float source, float target, uint64_t startAtFrame, uint64_t fadeFrames) {
  uint64_t now = ma_node_graph_get_time(ma_node_get_node_graph(pFader));
  uint64_t framesUntilStart = now > startAtFrame ? 0 : (startAtFrame - now);

  if (framesUntilStart > INT32_MAX >> 1) {
    printf("Fade scheduled very far in future (%"PRIu64" frames), skipping\n", framesUntilStart);
    return;
  }

  wp_playerlib_fader_fade newFade = {
    .source = source,
    .target = target,
  };
  wp_playerlib_fader_progress newProgress = {
    .totalFrames = (int32_t)fadeFrames,
    .progressFrames = -(int32_t)framesUntilStart,
    .atTargetInvoked = false,
  };
  atomic_store(&pFader->fade, newFade);
  atomic_store(&pFader->progress, newProgress);
  printf("Set fader %f-%f between frames %"PRIu64"-%"PRIu64"\n", source, target, startAtFrame, startAtFrame + fadeFrames);
}

void wp_playerlib_fader_set_target_starting_at_frame(wp_playerlib_fader* pFader, float target, uint64_t startAtFrame, uint64_t fadeFrames) {
  wp_playerlib_fader_fade currentFade = atomic_load(&pFader->fade);
  wp_playerlib_fader_progress currentProgress = atomic_load(&pFader->progress);
  float currentFadeProgress = faderProgressEased((float)currentProgress.progressFrames / (float)currentProgress.totalFrames);
  float currentFadeCurrent = currentFade.source + (currentFadeProgress * (currentFade.target - currentFade.source));
  wp_playerlib_fader_set_source_and_target_starting_at_frame(pFader, currentFadeCurrent, target, startAtFrame, fadeFrames);
}

void wp_playerlib_fader_set_target(wp_playerlib_fader* pFader, float target, uint64_t fadeFrames) {
  uint64_t now = ma_node_graph_get_time(ma_node_get_node_graph(pFader));
  wp_playerlib_fader_set_target_starting_at_frame(pFader, target, now, fadeFrames);
}

void wp_playerlib_fader_process_pcm_frames(ma_node* p_node, const float** ppFramesIn, ma_uint32* pFrameCountIn, float** ppFramesOut, ma_uint32* pFrameCountOut) {
  (void)p_node;
  (void)pFrameCountIn;

  wp_playerlib_fader *pFader = (wp_playerlib_fader*)p_node;
  const float* pFramesIn = ppFramesIn[0];
  float* pFramesOut = ppFramesOut[0];
  ma_uint32 frameCount = *pFrameCountOut;

  wp_playerlib_fader_fade fade = atomic_load(&pFader->fade);
  wp_playerlib_fader_progress progress = atomic_load(&pFader->progress);
  bool progressStateChanged = false;

  if (progress.progressFrames >= progress.totalFrames || progress.progressFrames < -(int32_t)frameCount) {
    float value = progress.progressFrames >= progress.totalFrames ? fade.target : fade.source;
    if (value == 1.0f) {
      // unity gain fast path
      ma_copy_pcm_frames(pFramesOut, pFramesIn, frameCount, ma_format_f32, 2);
    } else if (value == 0.0f) {
      // zero gain fast path
      ma_silence_pcm_frames(pFramesOut, frameCount, ma_format_f32, 2);
    } else {
      // constant gain
      for (ma_uint32 i = 0; i < frameCount; i++) {
        ma_uint32 i2 = i * 2;
        pFramesOut[i2] = pFramesIn[i2] * value;
        pFramesOut[i2 + 1] = pFramesIn[i2 + 1] * value;
      }
    }
    if (progress.progressFrames < 0) {
      progress.progressFrames += frameCount;
      progressStateChanged = true;
    }
  } else {
    // fade
    for (ma_uint32 i = 0; i < frameCount; i++) {
      float fadeProgress = faderProgressEased((float)progress.progressFrames++ / (float)progress.totalFrames);
      float fadeCurrent = fade.source + (fadeProgress * (fade.target - fade.source));
      fadeCurrent = fmaxf(0.0f, fminf(1.0f, fadeCurrent));
      ma_uint32 i2 = i * 2;
      pFramesOut[i2] = pFramesIn[i2] * fadeCurrent;
      pFramesOut[i2 + 1] = pFramesIn[i2 + 1] * fadeCurrent;
    }
    progressStateChanged = true;
  }

  if (!progress.atTargetInvoked && progress.progressFrames >= progress.totalFrames) {
    progress.atTargetInvoked = true;
    if (pFader->onTargetReached != NULL) {
      pFader->onTargetReached(pFader->onTargetReachedContext);
    }
    progressStateChanged = true;
  }

  if (progressStateChanged) {
    atomic_store(&pFader->progress, progress);
  }

}

static ma_node_vtable wp_playerlib_fader_vtable =
{
    wp_playerlib_fader_process_pcm_frames, // The function that will be called to process your custom node. This is where you'd implement your effect processing.
    NULL,   // Optional. A callback for calculating the number of input frames that are required to process a specified number of output frames.
    1,      // 1 input bus.
    1,      // 1 output bus.
    0       // Default flags.
};

ma_result wp_playerlib_fader_init_with_callback(wp_playerlib_fader* pFader, float initialValue, void (*onTargetReached)(void* context), void* onTargetReachedContext, ma_engine* engine) {
  wp_playerlib_fader_fade fade = {
    .source = initialValue,
    .target = initialValue,
  };
  wp_playerlib_fader_progress progress = {
    .totalFrames = 0,
    .progressFrames = 0,
    .atTargetInvoked = true
  };
  atomic_store(&pFader->fade, fade);
  atomic_store(&pFader->progress, progress);
  pFader->onTargetReached = onTargetReached;
  pFader->onTargetReachedContext = onTargetReachedContext;

  ma_uint32 inputChannels[1];
  ma_uint32 outputChannels[1];
  inputChannels[0] = 2;
  outputChannels[0] = 2;
  ma_node_config nodeConfig = ma_node_config_init();
  nodeConfig.vtable = &wp_playerlib_fader_vtable;
  nodeConfig.pInputChannels = inputChannels;
  nodeConfig.pOutputChannels = outputChannels;

  return ma_node_init(ma_engine_get_node_graph(engine), &nodeConfig, NULL, pFader);
}

ma_result wp_playerlib_fader_init(wp_playerlib_fader* pFader, float initialValue, ma_engine* engine) {
  return wp_playerlib_fader_init_with_callback(pFader, initialValue, NULL, NULL, engine);
}

void wp_playerlib_fader_destroy(wp_playerlib_fader* pFader) {
  ma_node_uninit(pFader, NULL);
}
