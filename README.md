# Suspension Coffin

Adds a fixed suspension coffin vehicle.

- Entering the coffin sets game speed to `100`.
- Exiting the coffin restores game speed to `1`.
- If multiple players are in coffins, speed remains `100` until the last tracked player exits.

## Release packaging

This mod currently targets Factorio 2.1.

Build the release package with:

```sh
./scripts/package.sh
```

The release ZIP is written to `dist/`.

Deploy the release package to the local Factorio mods directory with:

```sh
./scripts/deploy.sh
```

## License

Suspension Coffin is released under the MIT License. See `LICENSE`.
