# ADEduKit

This is the admaDIC EduKit Framework, which provides convenience features for
supporting ClassKit (see [Apple Documentation for ClassKit](https://developer.apple.com/classkit/)). 

## Build

Open a terminal in the project directory and execute the build script:

```shell
$ sh tools/build.sh
```

This will create `ADEduKit.xcframework` in the `build` directory.
(The build directory is excluded from source control.)

## Directories

- `tools`: Contains the build shell script
- `ADEduKit`: the framework's main source files
    - `doc`: Some documentation
    - `res_private`: Framework internal resources
    - `deprecated`: Deprecated parts of the framework
    - `impl`: Implementation classes
    - `ui`: Convenience UI components

## API

- `Facade`: Main entry point for users; Provides access to the `ContainerRepo` instance
- `ADEduKitAPI.swift`:
    - `ModelNode`: Base class for ClassKit context node representations
    - `Metadata`: Base class for Metadata of a set of model objects
    - `Container`: Base class for a container, which holds the root model node and the metadata
    - `ContainerRepo`: Base class for the container repository
    - `ContainerProviderKeys`: Keys for provider info dictionaries
    - `ContainerProvider`: Base class for container information providers
    - `ClassKitUtil`: Base class for ClassKit helper functions
    - `AppConfig`: Base class for application specific configuration
    - `ProgressState`: Represents task progress with ability to select previous and next tasks
    - `DefaultCLSContextProvider`: Default implementation of a `CLSContextProvider`
- `ADEduLocaleUtil`: Deprecated locale helpers
- `Opaque`: Preliminary
- `ADLog`: A logger class supporting logging to a shared directory, which can be observed by an app; allows to see the live log output of a ClassKit ContentProvider in an app, which has access to the shared directory
