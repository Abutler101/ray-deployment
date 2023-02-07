import string

import ray
import numpy as np
import pandas as pd


@ray.remote
def generate_data() -> pd.DataFrame:
    """An intentionally slow method that generates a dataframe"""
    a = pd.DataFrame(["num", "letter", float])
    for _ in range(100_000):
        a.append([np.random.randint(0, 100), np.random.choice(string.ascii_lowercase), np.random.random()])
    return a