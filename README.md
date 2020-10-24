#  Graphism (Swift Edition)

## GRPH Language

This Swift version of the GRPH runtime runs GRPH 1.11.

**Code in GRPH with [BBTCEnvironment](http://elementalcube.infos.st/product/6)**

BBTCEnvironment 2.12.3 supports running Graphism CLI. Running Graphism macOS or iOS requires copying/opening with the app directly.  
BBTCEnvironment 2.12.3 doesn't support GRPH 1.11 features (GRPH 1.11 scripts will not be checked for errors)

This project currently lacks support for a lot of Java Edition features.

## GRPH 1.11

GRPH 1.11 introduces :
- #setting (changing settings, WIP)
- #typealias (renaming a type, `#typealias farray {float}` for example)
- #compiler (settings, example `#compiler indent spaces`)
- #switch-#case-#default
- #foreach &elem : arr —> inout foreach for modifying values in the array
- Constructors for non-shape simple types & arrays
- Array.length
- Support for variables with the same name in different scopes
- #elif alias for #elseif
- Value type assignment
- #break ::LABEL & #break 3 (multiple scopes)
- **Swift Edition doesn't support #goto, and labels must precede blocks**

Smaller features/fixes :

- For each debug shows associated variable & catch & array modification correcltly
- Tweaks between functions and methods
- stringToInteger/Float, getMousePos return optionals
- stdio>getLinesInstring string.random>shuffled
- random>randomString has an extra optional parameter
- reflect>getVersion parameter is optional
- "As" infers the type. Casting as mixed has no autounboxing
- New autoboxing and unboxing that can be disabled
- Default return type for function can use its parameters
- Using the ordinal sign (º) instead of rotation sign (°) is now supported

## Targets

They all can only execute and show results. They don't support writing code. For writing code, use [BBTCEnvironment](http://elementalcube.infos.st/product/6).

- **Graphism CLI**: Runs code headlessly. Runs on older macOS versions. Probably also on Linux with some changes
- **macOS**: runs on Big Sur, with a user interface
- **iOS**: runs on iPadOS 14
- **GraphismTests**: Unit testing

## Example projects

Example code can be found in [Snowy1803/Graphism-Projects](https://github.com/Snowy1803/Graphism-Projects)
These examples are designed for Graphism Java, and some of them will not run as-is in Graphism Swift.
