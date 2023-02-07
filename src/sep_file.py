import string

import ray
import numpy as np
import pandas as pd


@ray.remote
def generate_data() -> pd.DataFrame:
    """An intentionally slow method that generates a dataframe"""
    a = pd.DataFrame({"num": [], "letter": [], "float": []})
    for _ in range(100_000):
        a = a.append(
            {
                "num": np.random.randint(0, 100),
                "letter": np.random.choice(list(string.ascii_lowercase)),
                "float": np.random.random()
            },
            ignore_index=True
        )
    return a
