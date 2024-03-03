#pragma once
#include <stdbool.h>

void tether_open();

extern bool tether_shouldReload;
extern char tether_newMapBuffer[128];