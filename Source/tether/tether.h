#pragma once
#include <stdbool.h>

void tether_open();

void tether_setGameInfo(const char* map, const char* server, const char* mode);

extern bool tether_shouldReload;
extern char tether_newMapBuffer[128];