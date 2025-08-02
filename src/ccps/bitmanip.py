def embed_bit(byte: int, position: int, bit: int) -> int:
    if bit < 0 or bit > 1:
        raise ValueError(f"Bit to embed MUST be a 1 or a 0, received '{bit}'")
    mask = ~(1 << position)
    num = byte & mask
    return num | (bit << position)


def extract_bit(byte: int, position: int) -> int:
    return (byte >> position) & 1
