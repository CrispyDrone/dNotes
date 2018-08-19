#!/bin/bash

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
loadTags() {
	configContent=$(cat "$1")
	# use jq
	
}

# reads the bucket file one line at a time
# $1 = bucket file
parseBucket() {
	# regex to find opening tag

	# check whether it exists in tagFiles

	# if yes, keep reading file until it hits end tag, add content to readTagContent
	# if no, read next line for filepath, add tag + filepath to readTagFiles, keep reading file until it hits end tag, add content to readTagContent

	# do this until you hit end of file for bucketfile
}

# writes out all changes to the appropriate target files
exportChanges() {
	# for all tags in readTagFiles, add content in the corresponding tag of readTagContent to the file associated with the tag in readTagFiles
	# if file does not exist yet, create it (always .md file)
	# log this action
}

# exports the new tags to the configuration file
exportNewTags() {
	# for all tags in readTagFiles that are not in tagFiles, write them to the configuration file
}

# variables
# 1: TAG-FILES
tagFiles=
# 2: read TAG-FILES
readTagFiles=
# 3: read TAG-CONTENT
readTagContent=
# 4: empty bucket file
emptyFile=true
# 5: configFile filepath
configFile=
# 6: bucket file
bucketFile=

# parse command line arguments


# $1 = bucketFile, $2 = configFile
main() {
	loadTags $2
	parseBucket $1
	exportChanges
	exportNewTags
}

main $bucketFile $configFile
