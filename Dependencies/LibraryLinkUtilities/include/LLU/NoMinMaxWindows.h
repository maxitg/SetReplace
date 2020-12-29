/**
 * @file	NoMinMaxWindows.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	3/10/2017
 *
 * @brief	Include windows.h without \c min and \c max macros
 *
 */
#ifndef LLU_NOMINMAXWINDOWS_H
#define LLU_NOMINMAXWINDOWS_H

#ifdef _WIN32

/* Prevent windows.h from defining max and min macros. They collide with std::max, std::min, etc. */
#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <windows.h>

#undef NOMINMAX

#endif

#endif // LLU_NOMINMAXWINDOWS_H
