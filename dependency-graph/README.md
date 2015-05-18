# Hybris Extension Dependency Graph

This utility generates a pretty graph showing the dependencies of all installed extensions. It reads the localextensions.xml configuration and then creates a [Graphviz directed graph].

## Requires

* bash
* xmllint
* graphviz

		$ brew install graphviz

## Instructions

Call the script from the command line with a single argument, the path to your hybris directory. The hybris directory is the parent directory for bin, config, data, etc.

		$ bash generate_extension_dependency_graph.sh /path/to/hybris

Two output files will be created in the current directory: ```extensions.dot``` and ```extensions.pdf```. The pdf is the graph.

<svg xmlns="http://www.w3.org/2000/svg">
<circle id="greencircle" cx="30" cy="30" r="30" fill="green" />
</svg>


[Graphviz directed graph]: http://www.graphviz.org/Documentation/dotguide.pdf
