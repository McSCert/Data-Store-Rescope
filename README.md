# Data Store Rescope Tool

Data stores in Simulink are analogous to variables in traditional programming languages. Therefore, they should be restricted in scope to avoid inadvertent/unwanted access, hide low-level details, and reduce the number of inputs for testing.

The Data Store Rescope Tool (formerly known as the Data Store Push-Down Tool) identifies the data stores that have scopes larger than necessary. Then, the declaration (Data Store Memory block) of each identified data store is pushed down the model hierarchy to the lowest level possible, such that all the references to the data store memory are still within its scope. Also, if references to a data store are outside of its scope, the Data Store Rescope Tool can be used for auto-correction: the data store’s declaration is first moved to the model's top level, and then pushed-down to minimize data store's scope as previously described.

<img src="imgs/Cover.png" width="650">

## User Guide
For installation and other information, please see the [User Guide](doc/DataStoreRescope_UserGuide.pdf).

## Related Publications

Vera Pantelic, Steven Postma, Mark Lawford, Alexandre Korobkine, Bennett Mackenzie, Jeff Ong, Marc Bender, ["A Toolset for Simulink: Improving Software Engineering Practices in Development with Simulink,"](https://ieeexplore.ieee.org/document/7323083/) Proceedings of 3rd International Conference on Model-Driven Engineering and Software Development (MODELSWARD 2015), SCITEPRESS, 2015, 50-61. (Best Paper Award)

Vera Pantelic, Steven Postma, Mark Lawford, Monika Jaskolka, Bennett Mackenzie, Alexandre Korobkine, Marc Bender, Jeff Ong, Gordon Marks, Alan Wassyng, [“Software engineering practices and Simulink: bridging the gap,”](https://link.springer.com/article/10.1007/s10009-017-0450-9) International Journal on Software Tools for Technology Transfer (STTT), 2017, 1-23.

## Matlab Central

This tool is also available on the [Matlab Central File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/51160-data-store-rescope-tool).

[![View Data Store Rescope Tool on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/51160-data-store-rescope-tool)
