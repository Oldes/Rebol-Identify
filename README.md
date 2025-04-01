[![Rebol-Identify CI](https://github.com/Oldes/Rebol-Identify/actions/workflows/main.yml/badge.svg)](https://github.com/Oldes/Rebol-Identify/actions/workflows/main.yml)
[![Gitter](https://badges.gitter.im/rebol3/community.svg)](https://app.gitter.im/#/room/#Rebol3:gitter.im)

# Rebol/Identify
[Rebol3](https://github.com/Oldes/Rebol3) `identify` function which identifies file types using their _magic numbers_.

![rebol-identifier](https://github.com/user-attachments/assets/048889bc-b4d0-429f-9771-fe67b0c69e0c)

## Usage
```rebol
import identify               ;; import the module
identify %path/to/some/file
identify #{0000000C6A5020200D0A870A00000000667479706A707820}
```

