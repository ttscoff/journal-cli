# journal

[![RubyGems.org](https://img.shields.io/gem/v/journal-cli)](https://rubygems.org/gems/journal-cli)
[![GitHub Actions](https://github.com/ttscoff/journal-cli/actions/workflows/check.yml/badge.svg)](https://github.com/ttscoff/journal-cli/actions/workflows/check.yml)

A CLI for journaling to structured data, Markdown, and Day One

## Description

TODO

## Installation

Add this as a dependency to your project using [Bundler] with

```
$ bundle add journal-cli
```

[bundler]: https://bundler.io/

## Development and Testing

### Quickstart

```
$ git clone https://github.com/ttscoff/journal-cli.git
$ cd journal-cli
$ bundle install
```

Run the command below

```
$ bundle exec rake
```

Open an interactive ruby console with

```
$ bundle exec rake
```

Primary development tasks are defined as [rake] tasks in the `Rakefile`
and available via `rake`.
View them with

```
$ bundle exec rake -T
```

[rake]: https://ruby.github.io/rake/

### Source code

The [source code] is hosted on GitHub.
Clone the project with

```
$ git clone git@github.com:ttscoff/journal-cli.git
```

[source code]: https://github.com/ttscoff/journal-cli

### Requirements

You will need [Ruby] with [Bundler].

Be sure that all commands run under the correct Ruby version, e.g.,
if using [rbenv], install the correct version with

```
$ rbenv install
```

Install the development dependencies with

```
$ bundle install
```

[bundler]: https://bundler.io/
[ruby]: https://www.ruby-lang.org/
[rbenv]: https://github.com/rbenv/rbenv

### Publishing

Use [gem release] to release a new version.

Publishing may be triggered using a [workflow_dispatch on GitHub Actions].

[gem release]: https://github.com/svenfuchs/gem-release
[workflow_dispatch on github actions]: https://github.com/ttscoff/journal-cli/actions?query=workflow%3Aversion

## GitHub Actions

_GitHub Actions should already be configured: this section is for reference only._

The following repository secrets must be set on [GitHub Actions]:

- `RUBYGEMS_API_KEY`: RubyGems.org token for publishing gems.

These must be set manually.

### Secrets for Optional GitHub Actions

The version and format GitHub actions
require a user with write access to the repository.
Set these additional secrets to enable the action:

- `GH_TOKEN`: A personal access token for the user.
- `GIT_USER_NAME`: The GitHub user's real name.
- `GIT_USER_EMAIL`: The GitHub user's email.
- `GPG_PRIVATE_KEY`: The GitHub user's [GPG private key].
- `GPG_PASSPHRASE`: The GitHub user's GPG passphrase.

[github actions]: https://github.com/features/actions
[gpg private key]: https://github.com/marketplace/actions/import-gpg#prerequisites

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
