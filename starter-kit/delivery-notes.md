# Delivery Notes

## Flow

Work moves in small, frequent changes made on a feature branch, then merged through a Pull Request. Keeping each change small and merging regularly means nothing piles up and the main line of work keeps moving.

## Feedback

Fast signals come from Pull Request review and from checking the diff before merge. Where CI is set up, it runs automatically on push, so issues are caught and fixed before the change reaches `develop`.

## Learning

We improve by reviewing each PR and reflecting on what went well and what to change next time. That reflection is carried straight into the next change, so the process gets a little better each round.

## Reflection

- Tempted to take shortcuts by committing directly to `main` instead of going through a feature branch and Pull Request.
- The architectural decision that needed the most reasoning was the cloud service model, because it sets the direction for everything else.
- The first thing to improve as KijaniKiosk grows is automating with CI/CD and adding proper monitoring.
