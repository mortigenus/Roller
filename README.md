# ⚠️ WIP

# Roller

Rolling some dice. You can use it from the command line or add it to your app!

Currently supported expressions:
- Keep highest: 4d6kh3
- Keep lowest: 3d4kl1
- Drop highest: 3d4dh1
- Drop lowest: 4d6dl1
- Reroll equal: 2d4r1
- Reroll less: 2d4r<2
- Reroll less or equal: 2d4r<=2
- Reroll greater: 2d4r>2
- Reroll greater or equal: 2d4r>=3
- Explode equal: 2d4x4
- Explode less: 2d4x<2
- Explode less or equal: 2d4x<=2
- Explode greater: 2d4x>2
- Explode greater or equal: 2d4x>=3
- Count Successes equal: 2d4cs=4
- Count Successes less: 2d4cs<2
- Count Successes less or equal: 2d4cs<=2
- Count Successes greater: 2d4cs>2
- Count Successes greater or equal: 2d4cs>=3
- Multiple rolls in one: 4d6kh1 + 1d4 - 1

## TODO:
- Support critical success?
- Support negative numbers
- Refactor `roll()` method
