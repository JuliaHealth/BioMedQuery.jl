The [examples](https://github.com/bcbi/BioMedQuery.jl/tree/master/examples)
folder contains sample scripts demonstrating
how to use BioMedQuery's pre-assembled processes/workflows.
The following examples are available:

* [Search&Save PubMed]():  
* [Build MESH-UMLS map]():  
* [Occurrence Matrix]():  
* [Exporting Citations]():  

## Running the scripts


## Configuring local variables

**User Credentials**

Email addresses, passwords or any other type of credentials are expected to be
stored in your system as environment variables.

From a Julia session, you can set an environment variable using

`ENV["MY_PSWD"] = "MyPsWd"`

However, for this variable to be permanently available, you need to add that line to
your `~/.juliarc.jl` file.
