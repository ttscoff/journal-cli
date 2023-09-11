### 1.0.19

2023-09-11 10:52

#### IMPROVED

- Better output of date types in Markdown formats

### 1.0.18

2023-09-09 12:29

#### IMPROVED

- Include the answers to all questions as YAML front matter when writing individual Markdown files. This allows for tools like [obsidian-dataview](https://github.com/blacksmithgu/obsidian-dataview) to be used as parsers

#### FIXED

- Daily markdown was being saved to /journal/entries/KEY/entries
- Missing color library

### 1.0.17

2023-09-08 07:21

#### IMPROVED

- More confirmation messages when saving

### 1.0.16

2023-09-07 11:12

#### IMPROVED

- Use optparse for command line options
- Completion-friendly list of journals with `journal -l`

### 1.0.15

2023-09-07 07:57

#### FIXED

- Messed up the fix for nested keys

### 1.0.14

2023-09-07 07:35

#### FIXED

- Keys nested with dot syntax were doubling

### 1.0.13

2023-09-07 06:57

#### NEW

- Allow entries_folder setting for top level and individual journals to put JSON and Markdown files anywhere the user wants

#### IMPROVED

- If a custom folder doesn't exist, create it automatically
- Updated documentatioh

### 1.0.12

2023-09-06 16:43

#### IMPROVED

- Add note about ctrl-d to save multiline input

### 1.0.11

2023-09-06 16:37

#### IMPROVED

- Write a demo config file for editing

### 1.0.10

2023-09-06 16:03

#### IMPROVED

- Refactoring code

### 1.0.9

2023-09-06 11:58

#### NEW

- If the second argument is a natural language date, use the parsed result instead of the current time for the entry

### 1.0.5

2023-09-06 09:24

### 1.0.0

2023-09-06 09:23

#### NEW

- Initial journal command
- Multiple journals, multiple sections
