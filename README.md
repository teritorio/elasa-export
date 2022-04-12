# Elasa Print

Render PDF from template using Elasa API data.

## Template fields

- d.settings : API settings
- d.favorites : Array of API POIs

### Extra computed fields

- `phones` from `phone` array
- `adress` from `addr:*` fields

# Templates

How to make template: https://carbone.io/documentation.html#building-a-template

## Inlcude Fonts on LibreOffice

On custom font usage, embedind is required. See [LibreOffice Help](https://help.libreoffice.org/latest/lo/text/shared/01/prop_font_embed.html?msclkid=48319268ba6411ec8f1b79ede8dea26d)

## Docker

```
docker-compose build
docker-compose up -d
```
