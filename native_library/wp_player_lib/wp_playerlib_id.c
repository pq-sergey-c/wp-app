#include <stdlib.h>
#include <time.h>


uint32_t wp_playerlib_id_next(void) {
    static int seeded = 0;
    if (!seeded) {
        srand(time(NULL));
        seeded = 1;
    }
    return (uint32_t)rand();
}
