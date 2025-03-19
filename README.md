# README.md

## LyricLab
A web service designed to help language learners expand their Mandarin vocabulary through Taiwanese songs. LyricLab's goal is to make learning more convenient and enjoyable.

Please also note the Web API that it uses: [https://github.com/SECutiee/ScanChat-api](https://github.com/Akira1906/LyricLab-API)

## Project Overview
LyricLab involves the design and implementation of a database for managing songs, lyrics, vocabulary, and recommendations with related attributes. The database is created and managed using Sequel, a Ruby toolkit for interacting with SQL databases. LyricLab pulls song information (title, artist, popularity, etc.) as well as lyrics from the Spotify and LrcLib APIs. Users can select one of the language levels and search for a song, generating a vocabulary list based on the selected level and the lyrics of the specified song. Users can then select specific words to see more learning information such as translations, pinyin, and example sentences.

## Domain Entities
The primary domain entities for this project are:

- **Lyrics**: Represents individual song lyrics with associated metadata such as language and type (e.g., instrumental or not).
- **Songs**: Represents songs with attributes including title, popularity, and artist information. Each song links to `lyrics` and `vocabulary` entries.
- **Vocabularies**: Represents sets of language-level vocabulary associated with words.
- **Words**: Represents individual words with their characters, pinyin, translation, and additional metadata.
- **Recommendations**: Represents song recommendations with associated metadata like artist and Spotify ID.
- **VocabulariesFilteredWords**: A join table that associates `vocabularies` and `words` entities.

### Attributes of the `lyrics` Entity:
- **id** (Primary Key)
- **text**: The actual lyrics text.
- **is_mandarin**: Boolean indicating if the lyrics are in Mandarin.
- **is_instrumental**: Boolean indicating if the lyrics are instrumental.
- **created_at**: Timestamp of creation.
- **updated_at**: Timestamp of last update.

### Attributes of the `songs` Entity:
- **id** (Primary Key)
- **lyrics_id** (Foreign Key): References `id` in the `lyrics` table.
- **vocabulary_id** (Foreign Key): References `id` in the `vocabularies` table.
- **title**: Title of the song (required).
- **spotify_id**: Unique Spotify identifier (required).
- **popularity**: Popularity score (required).
- **album_name**: Album name (required).
- **artist_name_string**: Name of the artist(s) (required).
- **cover_image_url_big**, **cover_image_url_medium**, **cover_image_url_small**: URLs for cover images.
- **search_counter**: Number of times searched (default 0).
- **explicit**: Boolean for explicit content (default `false`).
- **created_at**, **updated_at**: Timestamps.

### Attributes of the `vocabularies` Entity:
- **id** (Primary Key)
- **language_level**: Describes the proficiency level of the vocabulary set.
- **created_at**, **updated_at**: Timestamps.

### Attributes of the `words` Entity:
- **id** (Primary Key)
- **characters**: The word characters (required).
- **translation**: Translation of the word (required).
- **pinyin**: Pronunciation guide (required).
- **difficulty**, **definition**, **word_type**, **example_sentence**: Additional attributes.
- **created_at**, **updated_at**: Timestamps.

### Attributes of the `recommendations` Entity:
- **id** (Primary Key)
- **title**: Title of the recommendation (required).
- **artist_name_string**: Name of the artist(s) (required).
- **search_cnt**: Number of times searched (required).
- **spotify_id**: Unique Spotify identifier (required).
- **created_at**, **updated_at**: Timestamps.

### Attributes of the `vocabularies_filtered_words` Join Table:
- **vocabulary_id**: Foreign Key referencing `vocabularies`.
- **filtered_word_id**: Foreign Key referencing `words`.

## Entity-Relationship Diagram (ERD)
Below is a conceptual representation of the database structure:

```
+-------------+       +---------------+     +---------------+
|   lyrics    |       |   songs       |     | vocabularies  |
+-------------+       +---------------+     +---------------+
| id          |------>| lyrics_id     |<----| id            |
| text        |       | vocabulary_id |     |               |
| is_mandarin |       | title         |+--->| language_level|
| is_instr.   |       | spotify_id    ||    | created_at    |
| created_at  |       | ...           ||    | updated_at    |
| updated_at  |       +---------------+|    +---------------+
+-------------+                        |             ^
                                       |             |
+-------------+       +----------------------------+ |
|   words     |<------| vocabularies_filtered_words| |
+-------------+       +----------------------------+ |
| id          |       | vocabulary_id              |-+
| characters  |       | filtered_word_id           |
| translation |       +----------------------------+
| pinyin      |
| ...         |
| created_at  |
| updated_at  |
+-------------+

+--------------------+
|  recommendations   |
+--------------------+
| id                 |
| title              |
| artist_name_string |
| search_cnt         |
| spotify_id         |
| created_at         |
| updated_at         |
+--------------------+
```

### ERD Explanation:
- **lyrics table**: Stores lyrics data and links to `songs`.
- **songs table**: References `lyrics` and `vocabularies`.
- **vocabularies table**: Represents sets of words and is linked to `songs` and `words`.
- **words table**: Contains individual word information.
- **vocabularies_filtered_words**: A join table for many-to-many relationships between `vocabularies` and `words`.
- **recommendations table**: Contains song recommendation data.

## Setup
1. Create a personal Spotify API CLIENT_ID and CLIENT_SECRET.
2. Copy `config/secrets_example.yml` to `config/secrets.yml` and update the information.
3. Ensure the correct version of Ruby is installed (see `.ruby-version` for rbenv).
4. Run `bundle install` to install the required gems.
