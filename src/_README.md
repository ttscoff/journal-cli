# journal

[![RubyGems.org](https://img.shields.io/gem/v/journal-cli)](https://rubygems.org/gems/journal-cli)

<!--README-->
A CLI for journaling to structured data, Markdown, and Day One

## Description

The `journal` command reads a journal definition and provides command line prompts to fill it out. The results are stored in a JSON database for each journal, and can optionally output to Markdown (individual files per entry, daily digest, or one large file for the journal).

## Installation

First, you need [Gum](https://github.com/charmbracelet/gum) installed. The easiest way is with [Homebrew](https://brew.sh/):

```
$ brew install gum
```

Use RubyGems to install journal:

```
$ gem install journal-cli
```

If you run into errors, try running with the `--user-install` flag:

```
$ gem install --user-install journal-cli
```

> I've noticed lately with `asdf` that I have to run `asdf reshim` after installing gems containing binaries.

If you want to use Day One with journal, you'll need to [install the Day One CLI](https://dayoneapp.com/guides/tips-and-tutorials/command-line-interface-cli/).

## Configuration

A config must be created at `~/.config/journal/journals.yaml`:

```
$ mkdir -p ~/.config/journal
$ touch ~/.config/journal/journals.yaml
```

A skeleton file will be written the first time Journal is run if the config file doesn't exist.

This file contains a YAML definition of your journal. Each journal gets a top-level key, which is what you'll specify it with on the command line. It gets a few settings, and then you define sections containing questions.

### Weather

You can include weather data automatically by setting a question type to 'weather'. In order for this to work, you'll need to define `zip` and `weather_api` keys. `zip` is just your zip code, and `weather_api` is a key from WeatherAPI.com. Sign up [here](https://www.weatherapi.com/) for a free plan, and then visit the [profile page](https://www.weatherapi.com/my/) to see your API key at the top.

### Journal configuration

Edit the file at `~/.config/journal/journals.yaml` following this structure:

```yaml
# Where to save all journal entries (unless this key is defined inside the journal). 
# The journal key will be appended to this to keep each journal separate
entries_folder: ~/.local/share/journal/ 
journals:
  daily: # journal key, will be used on the command line as `journal daily`
    dayone: true # Enable or disable Day One integration
    journal: Journal # Day One journal to add to (if using Day One integration)
    markdown: daily # Type of Markdown file to create, false to skip (can be daily, individual, or digest)
    title: Daily Journal # Title for every entry, date will be appended where needed
    sections: # Required key
      - title: null # The title for the section. If null, no section header will be created
        key: journal # The key for the data collected, must be one word, alphanumeric characters and _ only
        questions: # Required key
          - prompt: How are you feeling? # The question to ask
            key: journal # alphanumeric characters and _ only, will be nested in section key
            type: multiline # The type of entry expected (numeric, string, or multiline)
```

Keys must be alphanumeric characters and `_` (underscore) only. Titles and questions can be anything, but if they contain a colon (:), you'll need to quote the string.

The `entries_folder` key can be set to save JSON and Markdown files to a custom, non-default location. The default is `~/.local/share/journal`. This key can also be used within a journal definition to offer custom save locations on a per-journal basis.

A more complex configuration file can contain multiple journals with multiple questions defined:

```yaml
zip: 55987 # Your zip code for weather integration
weather_api: XXXXXXXXXXXX # Your weatherapi.com API key
journals: # required key
  mood: # name of the journal
    entries_folder: ~/Desktop/Journal/mood # Where to save this specific journal's entries
    journal: Mood Journal # Optional, Day One journal to add to
    tags: [checkin] # Optional, array of tags to add to Day One entries
    markdown: individual # Can be daily or individual, any other value will create a single file
    dayone: true # true to log entries to Day One, false to skip
    title: "Mood checkin %M" # The title of the entry. Use %M to insert AM or PM
    sections: # required key
      - title: Weather # Title of the section (will create template sections in Day One)
        key: weather # the key to use in the structured data, will contain all of the answers
        questions: # required key
          - prompt: Current weather # The prompt shown on the command line, will also become a header in the journal entries (Markdown, Day One)
            key: weather.forecast # if a key contains a dot, it will create nested data, e.g. `{ 'weather': { 'forecast': data } }`
            type: weather # Set this to weather for weather data
      - title: Health # New section
        key: health 
        questions:
          - prompt: Health rating
            key: health.rating
            type: numeric # type can be numeric, string, or multiline
            min: 1 # Only need min/max definitions on numeric types (defaults 1-5)
            max: 5
          - prompt: Health notes
            key: health.notes
            type: multiline
      - title: Journal # New section
        key: journal
        questions:
          - prompt: Daily notes
            key: notes
            type: multiline
  daily: # New journal
    journal: Journal
    markdown: daily
    dayone: true
    title: Daily Journal
    sections:
      - title: null
        key: journal
        questions:
          - prompt: How are you feeling?
            key: journal
            type: multiline
```

A journal must contain a `sections` key, and each section must contain a `questions` key with an array of questions. Each question must (at minimum) have a `prompt`, `key`, and `type`.

## Usage

Once your configuration file is set up, you can just run `journal JOURNAL_KEY` to begin prompting for the answers to the configured questions. 

If a second argument contains a natural language date, the journal entry will be set to that date instead of the current time. For example, `journal mood "yesterday 5pm"` will create a new entry (in the journal configured for `mood`) for yesterday at 5pm.

Answers will always be written to `~/.local/share/journal/[KEY]/[KEY].json` (where [KEY] is the journal key, one data file for each journal). If you've specified a top-level custom path with `entries_folder` in the config, entries will be written to `[top level folder]/[KEY]/entries`. If you've specified a custom path using `entries_folder` in the journal, entries will be written to `[custom folder]/entries`.  

If you've specified `daily` or `individual` Markdown formats, entries will be written to Markdown files in `~/.local/share/journal/[KEY]/entries`, either in a `[KEY]-%Y-%m-%d.md` file (daily), or in timestamped individual files. If `digest` is specified for the `markdown` key, a single file will be created at `~/.local/share/journal/[KEY]/entries/[KEY].md` (or a folder defined by `entries_folder`).

At present there's no tool for querying the dataset created. You just need to parse the JSON and use your language of choice to extract the data. Numeric entries are stored as numbers, and every entry is timestamped, so you should be able to do some advanced analysis once you have enough data.

### Answering prompts

Questions with numeric answers will have a valid range assigned. Enter just a number within the range and hit return.

Questions with type 'string' or 'text' will save when you hit return. Pressing return without typing anything will leave that answer blank, and it will be ignored when exporting to Markdown or Day One (an empty value will exist in the JSON database).

When using the mutiline type, you'll get an edit field that responds to most control-key navigation and allows insertion and movement. To save a multiline field, type CTRL-d.

<!--END README-->
## Contributing

Please submit and comment on bug reports and feature requests.

To submit a patch:

1. Fork it (https://github.com/ttscoff/journal-cli/fork).
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Make changes.
4. Commit your changes (`git commit -am 'Add some feature'`).
5. Push to the branch (`git push origin my-new-feature`).
6. Create a new Pull Request.

## License

This Ruby gem is licensed under the MIT license.

## Warranty

This software is provided by the copyright holders and contributors "as is" and
any express or implied warranties, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose are
disclaimed. In no event shall the copyright holder or contributors be liable for
any direct, indirect, incidental, special, exemplary, or consequential damages
(including, but not limited to, procurement of substitute goods or services;
loss of use, data, or profits; or business interruption) however caused and on
any theory of liability, whether in contract, strict liability, or tort
(including negligence or otherwise) arising in any way out of the use of this
software, even if advised of the possibility of such damage.
