# polar_test
Polar Team Pro API Test

## Installation
This project uses the lightweight [Ruby Sinatra](http://sinatrarb.com/) web framework. To install, navigate to the repo directory, then type:
```
bundle install
```
If bundler isn't installed, you first need to type `gem install bundler`.

There is a file called `config.yml.example`, **copy this file to `config.yml`**. Then edit it and supply your own Client ID and Client Secret, as obtained through [https://admin.polaraccesslink.com/](https://admin.polaraccesslink.com/).

## Running the server
```
ruby server.rb
```
Starts a server on `http://localhost:4567`.

If you want to edit the code and have the server automatically reload the changes, use:
```
rerun server.rb
```
to start the server instead.

## Issues, Problems
If there are issues installing gems, delete the file `Gemfile.lock` and then try again.

Otherwise, open an issue at https://github.com/compsy/polar_test/issues
