#define SDL_MAIN_HANDLED
#include <SDL3/SDL.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

static SDL_Window *window;
static SDL_Renderer *renderer;
static int frames;
static int max_frames;

static void finish(void)
{
    printf("frames=%d\n", frames);
    fflush(stdout);

    if (renderer) {
        SDL_DestroyRenderer(renderer);
    }
    if (window) {
        SDL_DestroyWindow(window);
    }
    SDL_Quit();

#ifdef __EMSCRIPTEN__
    emscripten_force_exit(0);
#else
    exit(0);
#endif
}

static void draw_frame(void *arg)
{
    (void)arg;

    SDL_SetRenderDrawColor(renderer, 18, 24, 38, 255);
    SDL_RenderClear(renderer);

    SDL_SetRenderDrawColor(renderer, 245, 180, 50, 255);
    SDL_FRect rect = {60.0f + (float)(frames % 120), 80.0f, 220.0f, 140.0f};
    SDL_RenderFillRect(renderer, &rect);

    SDL_SetRenderDrawColor(renderer, 70, 220, 240, 255);
    SDL_RenderLine(renderer, 0.0f, 0.0f, 640.0f, 360.0f);

    SDL_RenderPresent(renderer);
    frames++;

    if (frames >= max_frames) {
#ifdef __EMSCRIPTEN__
        emscripten_cancel_main_loop();
#endif
        finish();
    }
}

int main(int argc, char **argv)
{
    int seconds = 2;
    const char *requested_renderer = NULL;

    setvbuf(stdout, NULL, _IONBF, 0);

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--seconds") == 0 && i + 1 < argc) {
            seconds = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--renderer") == 0 && i + 1 < argc) {
            requested_renderer = argv[++i];
        }
    }
    if (seconds < 1) {
        seconds = 1;
    }
    max_frames = seconds * 60;

    if (!SDL_Init(SDL_INIT_VIDEO)) {
        fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
        return 1;
    }

    window = SDL_CreateWindow("lunarnix sdl3 renderer", 640, 360, 0);
    if (!window) {
        fprintf(stderr, "SDL_CreateWindow: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    renderer = SDL_CreateRenderer(window, requested_renderer);
    if (!renderer) {
        fprintf(stderr, "SDL_CreateRenderer(%s): %s\n",
                requested_renderer ? requested_renderer : "default",
                SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    printf("SDL=%d\n", SDL_GetVersion());
    printf("video_driver=%s\n", SDL_GetCurrentVideoDriver());
    printf("renderer=%s\n", SDL_GetRendererName(renderer));
    fflush(stdout);

#ifdef __EMSCRIPTEN__
    emscripten_set_main_loop_arg(draw_frame, NULL, 60, 1);
#else
    while (frames < max_frames) {
        SDL_Event event;

        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) {
                max_frames = frames;
                break;
            }
        }

        draw_frame(NULL);
        SDL_Delay(16);
    }
#endif

    return 0;
}
