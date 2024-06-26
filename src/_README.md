# journal


<!--README-->
[![RubyGems.org](https://img.shields.io/gem/v/journal-cli)](https://rubygems.org/gems/journal-cli)

A CLI for journaling to structured data, Markdown, and Day One

## Description

The `journal` command reads a journal definition and provides command line prompts to fill it out. The results are stored in a JSON database for each journal, and can optionally output to Markdown (individual files per entry, daily digest, or one large file for the journal).

## Installation

Use RubyGems to install journal:

```
$ gem install journal-cli
```

If you run into errors, try running with the `--user-install` flag:

```
$ gem install --user-install journal-cli
```

> I've noticed lately with `asdf` that I have to run `asdf reshim` after installing gems containing binaries.

If [Gum](https://github.com/charmbracelet/gum) is installed, it will be used for prettier input prompts and editing. The easiest way is with [Homebrew](https://brew.sh/):

```
$ brew install gum
```

If you want to use Day One with Journal, you'll need to [install the Day One CLI](https://dayoneapp.com/guides/tips-and-tutorials/command-line-interface-cli/). It's just one command:

```
$ sudo bash /Applications/Day\ One.app/Contents/Resources/install_cli.sh
```

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

> Zip codes beginning with zero (0) must be quoted. Use:
>
>    zip: '01001'

You can optionally set the key `temp_in:` to `f` or `c` to control what scale is used for temperatures.

If a question type is set to `weather.forecast`, the moon phase and predicted condition, high, and low will be included in the JSON data for the question. A full printout of hourly temps will be included in the Markdown/Day One output.

If the question type is `weather.current`, only the current condition and temperature will be recorded to the JSON, and a string containing "[TEMP] and [CONDITION]" (e.g. "64 and Sunny") will be recorded to Markdown/Day One for the question.

If the question type is `weather.moon`, only the moon phase will be output. Moon phase is also included in `weather.forecast` JSON and Markdown output.

### Journal Configuration

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
          - prompt: Current Weather
            key: weather.current
            type: weather.current
          - prompt: Weather Forecast # The prompt shown on the command line, will also become a header in the journal entries (Markdown, Day One)
            key: weather.forecast # if a key contains a dot, it will create nested data, e.g. `{ 'weather': { 'forecast': data } }`
            type: weather.forecast # Set this to weather for weather data
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

If a question has a key `secondary_question`, the prompt will be repeated with the secondary question until it's returned empty, answers will be joined together.

### Question Types

A question `type` can be one of:

- `text` or `string` will request a single-line string, submitted on return
- `multiline` for multiline strings (opens a readline editor, use ctrl-d to save)
- `weather` will just insert current weather data with no prompt
  * `weather.forecast` will insert just the forecast (using weather history for backdated entries)
  * `weather.current` will insert just the current temperature and condition (using weather history for backdated entries)
  * `weather.moon` will insert the current moon phase for the entry date
- `number` or `float` will request numeric input, stored as a float (decimal)
- `integer` will convert numeric input to the nearest integer
- `date` will request a natural language date which will be parsed into a date object

### Conditional Questions

You can have a question only show up based on conditions. Currently the only condition is time based. Just add a key called `condition` to the question definition, then include a natural language string like `before noon` or `after 3pm`. If the condition is matched, then the question will be displayed, otherwise it will be skipped and its data entry in the JSON will be null.

Conditions can be applied to individual questions, or to entire sections, depending on where the `condition` key is placed.

### Naming Keys

If you want data stored in a nested object, you can set a question type to `dictionary` and set the prompt to `null` (or just leave the key out), but give it a key that will serve as the parent in the object. Then in the nested questions, give them a key in the dot format `[PARENT_KEY].[CHILD_KEY]`. Section keys automatically nest their questions, but if you want to go deeper, you could have a question with the key `health` and type `dictionary`, then have questions with keys like `health.rating` and `health.notes`. If the section key was `status`, the resulting dictionary would look like this in the JSON:

```json
{
  "date": "2023-09-08 12:19:40 UTC",
  "data": {
    "status": {
      "health": {
        "rating": 4,
        "notes": "Feeling much better today. Still a bit groggy."
      }
    }
  }
}
```

If a question has the same key as its parent section, it will be moved up the chain so that you don't get `{ 'journal': { 'journal': 'Journal notes' } }`. You'll just get `{ 'journal': 'Journal notes' }`. This offers a way to organize data with fewer levels of nesting in the output.

## Usage

Once your configuration file is set up, you can just run `journal JOURNAL_KEY` to begin prompting for the answers to the configured questions. 

If a second argument contains a natural language date, the journal entry will be set to that date instead of the current time. For example, `journal mood "yesterday 5pm"` will create a new entry (in the journal configured for `mood`) for yesterday at 5pm.

Answers will always be written to `~/.local/share/journal/[KEY].json` (where [KEY] is the journal key, one data file for each journal). If you've specified a top-level custom path with `entries_folder` in the config, entries will be written to `[top level folder]/[KEY].json`. If you've specified a custom path using `entries_folder` within the journal, entries will be written to `[custom folder]/[KEY].json`.  

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
