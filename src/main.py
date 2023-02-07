import ray

from sep_file import generate_data


def main():
    ray.init(address="ray://0.0.0.0:10001")
    print("connected to ray cluster")
    df_ref = generate_data.remote()
    print(f"got Ref: {df_ref}")


if __name__ == '__main__':
    main()
