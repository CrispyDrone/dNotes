#!/bin/bash

# debugging
set -x
trap read debug
# set -o functrace

# enable extended pattern matching
shopt -s extglob

# If an error occurs, exit script
set -e

# Commands:
# dNotes FILENAME
# empties FILENAME, sends content to appropriate files, uses $TAG_FILES as the configuration file

# dNotes FILENAME -p
# preserves "bucket file", and sends content to appropriate files, uses $TAG_FILES as the configuration file

# dNotes FILENAME -c FILENAME1
# empties FILENAME, sends content to appropriate files, uses tags found in FILENAME1, sets FILENAME1 as environment variable $TAG_FILES

# dNotes man
# opens man page

# <@TAG>\r\nCONTENT\r\n</@TAG> will be the syntax for creating a block of content to send to a specific TAG, that is:
# <@TAG> followed by a newline, followed by the actual content, followed by a new line, followed by </@TAG>
# If this tag does not yet exist, an absolute path has to be added on a new line before the actual content like so: 

# <@TAG>
# C:\Users\Eigenaar\Projects\BWSort
# CONTENT
# </@TAG>

# The configuration file will be a JSON file, which is very easy to modify. There are tools to help with reading them in a command line, such as jq.

# what would be a good flow for the script? 
# I think first the configuration file need to be read ONCE, so you have all tags loaded into the script. 
# Then the program can start reading the "bucket file", one line at a time, but maybe not open the actual target file(s) just yet, but instead per used tag, keep track of all content that needs to be added, and do the write ONCE at the end
# If a tag that doesn't exist is encountered during the "bucket file" reading, add it to the in-memory dictionary, together with the file location
# After the bucket file is entirely read, write out all changes to the appropriate files (create if necessary)
# After writing out all content changes, (over)write the entire configuration file based on the new in memory one...


man() {
	cat << EOF


Introduction:


Commands:


Syntax:

EOF
}

# loads all TAG-FILES couples into memory, from the configuration file
# $1 = config file location

# might be unnecessary, jq makes it really easy to look up a specific tag straight from the json, it's a json parser after all. So I might just load the entire config file AS json into memory
# loadTags() {
# 	# use jq
# 	tagFiles=$(cat "$1" | jq-win64.exe '.[] | .Tag + "|" + .Path')
# }

# loads config file
# $1 = config filepath
loadTags() {
	configFile=$(< "$1")
}
# reads the bucket file one line at a time
# $1 = bucket filepath
parseBucket() {
	# bucketFile=$(cat "$1")
	# regex to find opening tag
	isOpeningTagRegex="^<@.*>"
	# regex to find end tag
	isEndTagRegex="^</@.*>"
	# actually you should base the second regex on the tag identified in with the first one... but for now let's attempt the general case

	readingTag=false
	tagExists=false
	tag=
	# iterate over each line
	while IFS='' read -r line || [[ -n "$line" ]]
	do
		if [ $readingTag = false ]
		then
			# echo "$line"
			if [[ $line =~ $isOpeningTagRegex ]]
			then
				readingTag=true
				tag=$(jq "$jqname" "$configFile" ".[] | select(.Tag == \"$(echo "$line" | sed 's/<@\(.*\)>/\1/')\") | .Tag")
				tag=$(echo "$tag" | sed 's/"\(.*\)"/\1/')
				if [ -z "$tag" ]
				then
					# tagExists=false, so next line should be file path for new tag
					tag=$(echo "$line" | sed 's/<@\(.*\)>/\1/')
				else
					# tag exists in config file
					tagExists=true
				fi
			fi
		else
			if [ $tagExists = false ]
			then
				# remove \r or \r\n
				line=${line//[$'\r\n']}
				# line after opening tag, should be file path
				# how to check whether something is a valid filepath?? File does not need to exist yet!
				if [ ! -f "$line" ]
				then
					# create file, if it fails, file path is not valid, exit with error
					# if ! echo > "$line"
					if ! ( mkdir -p "$(dirname "$line")" && echo > "$line" )
					then
						echo "$line is not a valid file path!"
						exit 1
					fi
				fi
				# now is a file path, remember new tag-filepath combination
				# change tagExists to true
				configFile=$(jq "$jqname" "$configFile" ". + [{Tag: \"$tag\", Path: \"$line\"}]")
				tagExists=true

			else
				# continue reading and adding to tagContent until you hit the end tag
				if [[ $line =~ $isEndTagRegex ]]
				then
					readingTag=false
					tagExists=false
				else
					# add to tag's content, if key is already present, else add key and content
					if [[ -z $(jq "$jqname" "$readTagContent" ".[] | select(.Tag == \"$tag\")") ]]
					then
						readTagContent=$(jq "$jqname" "$readTagContent" ". + [{Tag: \"$tag\", Content: \"$line\"}]")
					else
						readTagContent=$(jq "$jqname" "$readTagContent" "[.[] | select(.Tag ==\"$tag\") |= { Tag: .Tag, Content: (.Content + \"$line\")}]")
					fi
				fi
			fi
		fi
	#done < <(< "$1")
	done < "$1"

	echo "Finished parsing bucket file!"

	# check whether it exists in tagFiles

	# if yes, keep reading file until it hits end tag, add content to readTagContent
	# if no, read next line for filepath, add tag + filepath to readTagFiles, keep reading file until it hits end tag, add content to readTagContent

	# do this until you hit end of file for bucketfile
}

# writes out all changes to the appropriate target files
exportChanges() {
	# for all tags in readTagContent write out content to the file associated with the tag
	# log this action

	# compactReadTagContent=$(jq "$jqname" "$readTagContent" ".[]")
        # compactReadTagContent= echo "$compactReadTagContent" | tr -d '\n\r' | sed 's/}/}\n/g' | sed 's/{[[:space:]]*/{/' | sed 's/:[[:space:]]*/:/g' | sed 's/,[[:space:]]*/,/'

	# for tuple in $(jq "$jqname" "$readTagContent" ".[]")
	# do
	# 	# how to assign to multiple variables? Or even avoid the variables 
	# 	tupleTag=$(jq "$jqname" "$tuple" ".Tag")
	# 	tupleContent=$(jq "$jqname" "$tuple" ".Content")
	# 	echo "writing to tag: $tupleTag following content: $tupleContent"
	# 	tupleTagFilePath=$(jq "$jqname" "$configFile" ".[] | select(.Tag == "$tupleTag") | .Path")
	# 	# echo "$tupleContent" >> "$tupleTagFilePath"
	# done


	for aTag in $(jq "$jqname" "$readTagContent" ".[] | .Tag")
	do
		aTag=$(echo "$aTag" | sed 's/"\(.*\)"/\1/')
		tupleContent=$(jq "$jqname" "$readTagContent" ".[] | select(.Tag == \"$aTag\") | .Content")
		tupleContent=$(echo "$tupleContent" | sed 's/"\(.*\)"/\1/')
		tupleFilePath=$(jq "$jqname" "$configFile" ".[] | select(.Tag == \"$aTag\") | .Path")
		tupleFilePath=$(echo "$tupleFilePath" | sed 's/"\(.*\)"/\1/')
		# tupleFilePath=$(echo "$tupleFilePath" | sed 's/\\\\/\\/g')
		echo "writing to tag: $aTag at filepath $tupleFilePath following content: $tupleContent"
		# make sure file path exists
		if [ ! -f "$tupleFilePath" ]
		then
			if ! ( mkdir -p "$(dirname "$tupleFilePath")" && echo > "$tupleFilePath" )
			then
				echo "$tupleFilePath is not a valid file path!"
				exit 1
			fi
		fi

		echo -ne "$tupleContent" >> "$tupleFilePath"
	done
	
	echo "Finished dispersing content!"
}

# exports the new tags to the configuration file
exportNewTags() {
	# for all tags in readTagFiles that are not in tagFiles, write them to the configuration file

	# actually for now just entirely overwrite the config file...
	# remove any \r and \n
	# echo "${configFile//[$'\r\n']}" > "$configFilePath"
	jq "$jqname" "$configFile" "." > "$configFilePath"
	echo "Finished exporting tags!"
}

createEnvironmentVariable() {
	case "$1" in
		setx)
			setx "$2" "$3"
			;;
		export)
			echo "$2"="$3" >> ~/.bashrc
			;;
		*)
			;;
		esac
}

# $1 = jqname, $2 = input, $3 = jq commands
jq() {
	case "$1" in
		jq-win64)
			echo "$2" | jq-win64.exe "$3"
			;;
		jq-win32)
			echo "$2" | jq-win32.exe "$3"
			;;
		*)
			echo "$2" | jq "$3"
			;;
	esac
}

# variables
# 2: TAG-FILES
# readTagFiles=[]
# 3: read TAG-CONTENT
readTagContent=[]
# 4: empty bucket file
emptyFile=true
# 5: configFile filepath
configFilePath=
# 6: configFile
configFile=
# 7: bucket file
# bucketFile=
# 8: bucket filepath
bucketFilePath=
# 9: command to create environment variable
createEnvironmentVariableCommandName=""
# 10: jq command
jqname=

case "$OSTYPE" in
	darwin*)
		# DEBUG: echo "I am a mac"
		jqname="jq"
		createEnvironmentVariableCommandName="export"
		;;
	linux-gnu)
		# DEBUG: echo "I am a linux or windows 10"
		# if [[ "$(grep -qi Microsoft /proc/sys/kernel/osrelease 2> /dev/null)" =~ *Microsoft* ]]
		if [[ "$(grep -qi Microsoft /proc/sys/kernel/osrelease 2> /dev/null)" =~ .*Microsoft.* ]]
		then
			if [ "$(uname -a)" == 'x86_64' ]
			then
				jqname="jq-win64"
			else
				jqname="jq-win32"
			fi
			createEnvironmentVariableCommandName="setx"
		else
			jqname="jq"
			createEnvironmentVariableCommandName="export"
		fi
		;;
	cygwin)
		# DEBUG: echo "I am windows using cygwin"
		if [[ "$(uname -a)" =~ x86_64 ]]
		then
			jqname="jq-win64"
		else
			jqname="jq-win32"
		fi
		createEnvironmentVariableCommandName="setx"
		;;
	msys)
		# DEBUG: echo "I am windows using minimal shell"
		if [[ "$(uname -a)" =~ x86_64 ]]
		then
			jqname="jq-win64"
		else
			jqname="jq-win32"
		fi
		createEnvironmentVariableCommandName="setx"
		;;
	*)
		# DEBUG: echo "I am something else..."
		jqname="jq"
		createEnvironmentVariableCommandName="export"
		;;
esac

# parse command line arguments

while [ ! $# -eq 0 ]
do
	case "$1" in
		# man page
		man)
			man
			exit 0;;
		# p flag
		-p)
			emptyFile=false
			shift
			;;

		# config file
		-c)
			if [ -f "$2" ]
			then
				configFilePath="$2"
				createEnvironmentVariable "$createEnvironmentVariableCommandName" "TAG_FILES" "$2"
				export TAG_FILES="$2"
				shift 2
			else
				echo "$2 is not a file!"
				exit 1
			fi
			;;

		# filename
		*)
			if [ -f "$1" ]
			then
				bucketFilePath="$1"
				shift
			else
				echo "$1 is not a file!"
				exit 1
			fi
			;;
	esac
done

# $1 = bucketFilePath, $2 = configFilePath
main() {
	loadTags "$2"
	parseBucket "$1"
	exportChanges
	exportNewTags
	if [[ $emptyFile == true ]]
	then
		echo > "$1"
	fi
}

main "$bucketFilePath" "$configFilePath"
