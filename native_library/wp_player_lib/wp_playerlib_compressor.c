typedef struct wp_playerlib_compressor {
    ma_node_base base;

    atomic_bool enabled;

    float alphaAttack;
    float oneMinusAlphaAttack;
    float alphaRelease;
    float oneMinusAlphaRelease;
    float threshold;
    float knee;
    float ratioInv;
    float makeup;

    float yL;
} wp_playerlib_compressor;

// https://www.eecs.qmul.ac.uk/~josh/documents/2012/GiannoulisMassbergReiss-dynamicrangecompression-JAES2012.pdf


float fastPow(float a, float b) {
  union {
    float d;
    int x;
  } u = { a };
  const float magicNumber = 1064866805.0f;
  u.x = (int)(b * (u.x - (int)magicNumber) + magicNumber);
  return u.d;
}

float fastLog10(float x) {
  // Retrieve a coarse log value from the exponent of the encoded float
  int* const intX = (int *)(&x);
  const int coarseLog2 = ((*intX >> 23) & 0xFF) - 127;
  // Set the exponent to 1
  *intX &= 0x007FFFFF;
  *intX |= 0x3F800000;
  // Improve the coarse log value using a quadratic approximation
  // of log over the range [1, 2]
  static const float A = -(1.0f / 3.0f);
  static const float B = 2.0f;
  static const float C = -(5.0f / 3.0f);
  x = (((A * x) + B) * x) + C + (float)(coarseLog2);
  // Convert log to base 10 and return
  static const float LogBase10of2 = 0.30102999566398119521373889472449f;
  return (x * LogBase10of2);
}

void wp_playerlib_compressor_process_pcm_frames(ma_node* p_node, const float** ppFramesIn, ma_uint32* pFrameCountIn, float** ppFramesOut, ma_uint32* pFrameCountOut) {
  (void)pFrameCountIn;
  wp_playerlib_compressor* compressor = (wp_playerlib_compressor*)p_node;

  const float* pFramesIn_0 = ppFramesIn[0];
  const float* pFramesIn_1 = ppFramesIn[1];
  float* pFramesOut_0 = ppFramesOut[0];

  ma_uint32 frameCount = *pFrameCountOut;

  bool enabled = atomic_load(&compressor->enabled);
  if (!enabled) {
    ma_copy_pcm_frames(pFramesOut_0, pFramesIn_0, frameCount, ma_format_f32, 2);
    return;
  }

  float alphaAttack = compressor->alphaAttack;
  float oneMinusAlphaAttack = 1.f - alphaAttack;
  float alphaRelease = compressor->alphaRelease;
  float oneMinusAlphaRelease = 1.f - alphaRelease;
  float threshold = compressor->threshold;
  float knee = compressor->knee;
  float ratioInv = compressor->ratioInv;
  float makeup = compressor->makeup;
    
  for (ma_uint32 i = 0; i < frameCount; i++) {
    ma_uint32 i2 = i * 2;
    ma_uint32 i2_1 = i2 + 1;

    float leftIn = pFramesIn_0[i2];
    float rightIn = pFramesIn_0[i2_1];
    float sidechainLeftIn = pFramesIn_1[i2];
    float sidechainRightIn = pFramesIn_1[i2_1];

    float combinedInDB = 20 * fastLog10(fabsf(sidechainLeftIn + sidechainRightIn)) - 3.f;

    float diffDB = 2.f * (combinedInDB - threshold);
    float outDB = 0.f;
    if (diffDB < -knee) {
      outDB = combinedInDB;
    } else if (diffDB <= knee && knee > 0) {
      float x = combinedInDB - threshold + knee * 0.5f;
      outDB = combinedInDB + ((ratioInv - 1.0) * x * x) / (2.0 * knee);
    } else {
      outDB = threshold + (combinedInDB - threshold) * ratioInv;
    }
    
    // Level detect
    float attenuationDB = combinedInDB - outDB;
    // float oldYL = compressor->yL;
    if (attenuationDB > compressor->yL) {
      compressor->yL = compressor->yL * alphaAttack + attenuationDB * oneMinusAlphaAttack;
    } else {
      compressor->yL = compressor->yL * alphaRelease + attenuationDB * oneMinusAlphaRelease;
    }
    // compressor->y1 = fmaxf(xL, alphaRelease * compressor->y1 + oneMinusAlphaRelease * xL);
    // attenuationDB = compressor->yL = alphaAttack * compressor->yL + oneMinusAlphaAttack * compressor->y1;
    float smoothedAttenuationDB = compressor->yL;

    smoothedAttenuationDB *= -1.f;
    smoothedAttenuationDB += makeup;

    // if (i == 0) {
    //     printf("in: %f, out: %f, attenuationDB immediate: %f, smoothed: %f\n", combinedInDB, outDB, attenuationDB, smoothedAttenuationDB);
    //     printf("xL: %f, oldYL: %f, newYL: %f, using: %s\n", 
    //           attenuationDB, 
    //           oldYL, 
    //           compressor->yL, 
    //           (attenuationDB > oldYL) ? "attack" : "release");
    // }

    float attenuation = fastPow(10.f, smoothedAttenuationDB / 20.f);
    float leftOut = leftIn * attenuation;
    float rightOut = rightIn * attenuation;

    pFramesOut_0[i2] = leftOut;
    pFramesOut_0[i2_1] = rightOut;
  }
  
}

static ma_node_vtable wp_playerlib_compressor_vtable = {
    wp_playerlib_compressor_process_pcm_frames,
    NULL,
    2,
    1,
    0
};

ma_result wp_playerlib_compressor_init(wp_playerlib_compressor* compressor, float tauAttack, float tauRelease, float threshold, float knee, float ratio, float makeup, ma_engine* engine) {
  ma_uint32 sampleRate = ma_engine_get_sample_rate(engine);

  atomic_store(&compressor->enabled, false);
  compressor->alphaAttack = expf(-1.0f / (sampleRate * tauAttack));
  compressor->oneMinusAlphaAttack = 1.f - compressor->alphaAttack;
  compressor->alphaRelease = expf(-1.0f / (sampleRate * tauRelease));
  compressor->threshold = threshold;
  compressor->knee = knee;
  compressor->ratioInv = 1.f / ratio;
  compressor->makeup = makeup;

  compressor->yL = 0.f;

  printf("Initializing compressor with tauAttack: %f, tauRelease: %f, alphaAttack: %f, alphaRelease: %f\n, threshold: %f, knee: %f, ratio: %f, makeup: %f\n", tauAttack, tauRelease, compressor->alphaAttack, compressor->alphaRelease, threshold, knee, ratio, makeup);

  ma_uint32 nodeInputChannels[2] = {2, 2};
  ma_uint32 nodeOutputChannels[1] = {2};
  ma_node_config config = ma_node_config_init();
  config.vtable = &wp_playerlib_compressor_vtable;
  config.pInputChannels = nodeInputChannels;
  config.pOutputChannels = nodeOutputChannels;

  return ma_node_init(ma_engine_get_node_graph(engine), &config, NULL, compressor);
}

void wp_playerlib_compressor_enable(wp_playerlib_compressor* compressor) {
  atomic_store(&compressor->enabled, true);
}

void wp_playerlib_compressor_destroy(wp_playerlib_compressor* compressor) {
  ma_node_uninit((ma_node*)compressor, NULL);
}

