# Project Tagging Scripts

This repository contains a set of Bash functions to help you organize and search for your projects using tags.

## How It Works

The scripts work by searching for a special file named `.tags` within each of your project directories located in `~/Projects`. Each `.tags` file should contain a list of tags, with one tag per line.

For example, for a project located at `~/Projects/my-website`, you could have a `~/Projects/my-website/.tags` file with the following content:

```
web
frontend
javascript
```

## Setup

To use these scripts, you need to source them in your shell's startup file (`~/.bashrc`, `~/.zshrc`, etc.).

1.  Clone this repository to a location on your computer, for example `~/Projects/tagging`.
2.  Add the following line to your `~/.bashrc` or `~/.zshrc` file:

    ```bash
    source ~/Projects/tagging/tag_search.sh
    ```

3.  Restart your shell or source the file manually for the changes to take effect:

    ```bash
    source ~/.zshrc
    ```

## Usage

### `ptag <tag>`

Search for projects that have a specific tag.

**Example:**

```bash
ptag web
```

This will list all projects that have the `web` tag in their `.tags` file.

If you run `ptag` without any arguments, it will list all unique tags available across all your projects.

### `ptags`

List all available tags and the number of projects associated with each tag. The list is sorted by the number of projects in descending order.

**Example:**

```bash
ptags
```

### `ptag-and <tag1> <tag2> ...`

Search for projects that have *all* of the specified tags (an AND search).

**Example:**

```bash
ptag-and web javascript
```

This will list all projects that are tagged with *both* `web` and `javascript`. 