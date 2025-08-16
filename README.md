<div align="center">  
  <img src="template/project/public/hxwell.svg" alt="HxWell Logo" width="120"/>  
    
  **HxWell is Modern, Laravel-inspired cross-platform web framework for Haxe**  
  
  [![Haxe](https://img.shields.io/badge/Haxe-4.3+-orange.svg)](https://haxe.org/)
  [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
  [![Documentation](https://img.shields.io/badge/docs-latest-brightgreen.svg)](#documentation)
  [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/hxwell/hxwell)
  [![Discord](https://img.shields.io/discord/1406250185943945316.svg?color=7289da)](https://discord.gg/D2JajXppjK)

</div>  
  
## Features  
  
- **Cross-Platform**: Deploy to JVM, C++, HashLink, PHP, and Neko  
- **Laravel-Inspired**: Familiar patterns and conventions for rapid development  
- **Type-Safe**: Full Haxe type system benefits with compile-time checks  
- **Modern Architecture**: Middleware pipeline, routing system, and modular design  
- **Database Abstraction**: Query builder with ORM-like model operations  
- **Session Management**: Session handling with UUID generation  
- **Static File Serving**: Optimized static http server
- **CLI Tools**: Comprehensive command-line interface for project management
  
## Installation  
  
```bash  
haxelib install hxwell
```

## Quick Start

### Create a New Project
```bash
haxelib run hxwell new my-app  
cd my-app
```

### Test
```bash
haxelib run hxwell test jvm
```

### Build
```bash
haxelib run hxwell build jvm  
haxelib run hxwell build cpp  
haxelib run hxwell build php  
haxelib run hxwell build hl  
haxelib run hxwell build neko
```

## Use as Static File Server
```bash
haxelib run hxwell up /path --start --port 3000
```

## Dependencies
- [haxe-concurrent](https://github.com/vegardit/haxe-concurrent)
- [uuid](https://github.com/flashultra/uuid)

## Credits
- [vegardit](https://github.com/vegardit)
  - Thanks to [haxe-concurrent](https://github.com/vegardit/haxe-concurrent) for bringing Java's excellent concurrent structure!
- [flashultra](https://github.com/flashultra)
  - [uuid](https://github.com/flashultra/uuid)
- [m0rkeulv](https://github.com/m0rkeulv)
  - If it wasn't for [intellij-haxe](https://github.com/HaxeFoundation/intellij-haxe), maybe I would never have write any haxe project :(

## Projects
- [airpsx](https://github.com/barisyild/airpsx)
