# dNotes
Bash script that sends contents of one file annotated with tags, described in a json config file, to different files on your system.

## Getting Started
### Prerequisites
+ jq: a lightweight and flexible command-line JSON processor [get it here](https://stedolan.github.io/jq/).

### Installing
Add jq to your PATH environment variable. Place the script inside a directory that is part of your PATH environment variable. Add executable permissions to the script:
```shell
chmod +x Your/Path/To/dNotes.sh
```

### Running the script

#### Setup
Before running the script, you need to have a *bucketfile* that contains any text at all that you want to add to the end of different files. Next you surround the text that should go 
to a particular file with the `<@TAG> INSERT TEXT <@/TAG>` elements. Meanwhile inside the config.json file you have a json array that consists of objects with a `Tag` and `Path` property (take care of escaping
characters such as backslashes, since it has to be valid JSON!):
```json
[
  {
    "Tag": "YourTag",
    "Path": "Path\\To\\Your\\File"
  }
]
```

You can create new tags by adding them to the config.json file, or by writing down the filepath after the opening tag, on a newline like so:
```
<@YourNewTag>
Your\Path\For\Your\New\Tag
...
</@YourNewTag>
```

#### Commands
Now you should be able to run the script by typing the following command in your favourite shell:
```shell
dNotes man
```
This will print some instructions (WIP).

```shell
dNotes -c "dNotes.config.json" "bucketFile.md"
```
Empties the bucketFile.md into the files described by the tags inside the config.json file.

#### Syntax
```shell
-p
	preserves the bucketFile instead of removing its contents
-c FILE
	filepath to the tag configuration file (has to be JSON)
```

## Bugs
+ Opening tags are currently case sensitive.
+ Ending tag does not need to match, which could give issues if you're using `</@>` in your content somehow.

## Towards the future
+ Option to clean config.json files by removing unused tags
+ Nested tags that allow content to be directed to particular locations inside a file instead of only appending to the end (this will require line numbers, or a sort of (unique) pattern to be specified to direct the insertion of text)
+ Complete rewrite of the script to be more efficient
  + Replace sed's with parameter expansion where possible
  + Remove inefficient bash loops
  + ...

## License

This project is licensed under the GNU GPLv3 license.
