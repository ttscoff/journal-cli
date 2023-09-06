# journal

[![RubyGems.org](https://img.shields.io/gem/v/journal-cli)](https://rubygems.org/gems/journal-cli)

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

This file contains a YAML definition of your journal. Each journal gets a top-level key, which is what you'll specify it with on the command line. It gets a few settings, and then you define sections containing questions.

### Weather

You can include weather data automatically by setting a question type to 'weather'. In order for this to work, you'll need to define `zip` and `weather_api` keys. `zip` is just your zip code, and `weather_api` is a key from WeatherAPI.com. Sign up [here](https://www.weatherapi.com/) for a free plan, and then visit the [profile page](https://www.weatherapi.com/my/) to see your API key at the top.

### Journal configuration

Edit the file at `~/.config/journal/journals.yaml` following this structure:

```yaml
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

A more complex configuration file can contain multiple journals with multiple questions defined:

```yaml
zip: 55987 # Your zip code for weather integration
weather_api: XXXXXXXXXXXX # Your weatherapi.com API key
journals: # required key
  mood: # name of the journal
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

Answers will always be written to `~/.local/share/journal/[KEY].json` (where [KEY] is the journal key, one data file for each journal). If you've specified `daily` or `individual` Markdown formats, entries will be written to Markdown files in `~/.local/share/journal/entries/[KEY]`, either in a `%Y-%m-%d.md` file (daily), or in timestamped individual files. If `digest` is specified for the `markdown` key, a single file will be created at `~/.local/share/journal/[KEY].md`.

At present there's no tool for querying the dataset created. You just need to parse the JSON and use your language of choice to extract the data. Numeric entries are stored as numbers, and every entry is timestamped, so you should be able to do some advanced analysis once you have enough data.

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
