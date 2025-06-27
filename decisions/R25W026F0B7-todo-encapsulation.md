# AriaFlow Encapsulation TODOs

<!-- @adr_serial R25W026F0B7 -->

## API Abstraction Issues

### High Priority

- [ ] Remove GPU/hardware-specific terminology from all public APIs
- [ ] Abstract away "backflow" terminology
- [ ] Hide "stages" concept from public API - make it an internal optimization

## Principle

The public API should describe WHAT the system does (parallel processing, optimization)
not HOW it does it (GPU convergence).

Internal documentation can be detailed about implementation, but public APIs should be generic.
