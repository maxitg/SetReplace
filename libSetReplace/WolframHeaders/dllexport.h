/*************************************************************************

                        Mathematica source file

        Copyright 1986 through 2015 by Wolfram Research Inc.

This material contains trade secrets and may be registered with the
U.S. Copyright Office as an unpublished work, pursuant to Title 17,
U.S. Code, Section 408.  Unauthorized copying, adaptation, distribution
or display is prohibited.

$Id$

*************************************************************************/

#ifndef DLL_EXPORT_H
#define DLL_EXPORT_H

/* Define DLL symbol export for LibraryLink etc */

#ifdef CONFIG_ENABLE_CUDA

#define DLLEXPORT
#define DLLIMPORT

#elif defined(_WIN32) || defined(_WIN64)

#define DLLEXPORT __declspec(dllexport)
#define DLLIMPORT __declspec(dllimport)

#else

#define DLLEXPORT __attribute__((__visibility__("default")))
#define DLLIMPORT

#endif

/* Definition for the Runtime Library */

#if defined(MRTL_DYNAMIC_EXPORT)

#define RTL_DLL_EXPORT DLLEXPORT

#elif defined(MATHDLL_EXPORTS)

#define RTL_DLL_EXPORT DLLIMPORT

#else

#define RTL_DLL_EXPORT

#endif

#endif /* DLL_EXPORT_H */

