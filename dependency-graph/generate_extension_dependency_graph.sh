#/bin/bash

# Generates a nice graph showing the dependencies of all installed extensions.
# Requires graphviz (brew install graphviz) and xmllint
# ref: http://www.graphviz.org/Documentation/dotguide.pdf

function usage()
{
	echo "Usage: $(basename "$0") hybris_dir"
	echo -e "\thybris_dir: path to parent hybris dir (with children bin, conf, data, etc), e.g. ~/project/hybris"
}

function check_for()
{
	command -v $1 >/dev/null 2>&1 || { echo >&2 "This script requires '$1' but it's not installed or not in your path!  Aborting."; exit 1; }
}

function get_hybris_extensions()
{
	config_file=$1

	#extensions=`xmllint --xpath '/hybrisconfig/extensions/extension[not(@dir)]/@name' $config_file | sed 's/name="\([^"]*\)"/\1/g'`
	extensions=`xmllint --xpath '/hybrisconfig/extensions/extension[not(contains(@dir,"ext-custom"))]/@dir' $config_file | sed 's/dir="\([^"]*\)"/\1/g'`
	for ext in $extensions
	do
		echo $ext | sed -e 's#.*/\([^/]*\)$#\1#g'
	done
}

function get_custom_extensions()
{
	config_file=$1
	
	#extensions=`xmllint --xpath '/hybrisconfig/extensions/extension[@dir]/@name' $config_file | sed 's/name="\([^"]*\)"/\1/g'`
	extensions=`xmllint --xpath '/hybrisconfig/extensions/extension[contains(@dir,"ext-custom")]/@dir' $config_file | sed 's/dir="\([^"]*\)"/\1/g'`
	for ext in $extensions
	do
		echo $ext | sed -e 's#.*/\([^/]*\)$#\1#g'
	done
}

function get_ext_path()
{
	ext=$1
	hybris_dir=$2

	result=$(find $hybris_dir/bin -maxdepth 2 -type d -name "$ext")
	if [ -e "$result/extensioninfo.xml" ]; then
		echo $result
	else
		echo "!! path for $ext not found !!" >&2
	fi
}

function get_dependencies_for_ext()
{
	ext=$1
	hybris_dir=$2

	ext_path=$(get_ext_path $ext $hybris_dir)
	extension_info=$ext_path/extensioninfo.xml

	required_extensions=$(xmllint --xpath '/extensioninfo/extension/requires-extension/@name' $extension_info | sed 's/name="\([^"]*\)"/\1/g')

	for req in $required_extensions; do
		echo -e "\t$ext -> $req;"
	done
}

function build_graph_file()
{
	dotfile=$1
	hybris_dir=$2
	config_file=$3

	echo "Building graph from $config_file"
	echo "digraph hybris_dependencies {" > $dotfile

	# add hybris extensions to the graph
	hybris_extensions=`get_hybris_extensions $config_file`
	for ext in $hybris_extensions; do
		echo "--> getting extension dependencies for $ext"
		get_dependencies_for_ext $ext $hybris_dir >> $dotfile
	done

	# add custom extensions to the graph
	custom_extensions=`get_custom_extensions $config_file`
	for ext in $custom_extensions; do
		echo "--> getting extension dependencies for $ext"
		get_dependencies_for_ext $ext $hybris_dir >> $dotfile
	done
	
	# give the custom extensions a different background color
	for ext in $custom_extensions; do
		echo -e "\t$ext [style=filled,color=black,fillcolor=lightblue]" >> $dotfile
	done

	echo "}" >> $dotfile
}

# check program prerequisites
check_for xmllint
check_for dot


hybris_dir=$1
if [ ! -d "$hybris_dir" ]; then
	echo "hybris_dir '$hybris_dir' not found!"
	usage
	exit 1
fi

config_file=$hybris_dir/config/localextensions.xml
if [ ! -f "$config_file" ]; then
	echo "config_file '$config_file' not found!"
	usage
	exit 1
fi

dotfile=extensions.dot
graphfile=extensions.pdf

build_graph_file $dotfile $hybris_dir $config_file
dot -Tpdf $dotfile -o $graphfile

echo "Created extension dependency graph: $graphfile"
