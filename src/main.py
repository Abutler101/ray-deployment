import math
import time
import ray
from pyspark.pandas import DataFrame
from pyspark.sql import SparkSession

TEST_TASK = "DATASETS"  # Possible values: GPU, CPU, DATASETS


@ray.remote
def cpu_test_method(num_samples: int):
    import random
    import math
    num_inside = 0
    for i in range(num_samples):
        x, y = random.uniform(-1, 1), random.uniform(-1, 1)
        if math.hypot(x, y) <= 1:
            num_inside += 1
    return num_inside


@ray.remote(num_gpus=1)
def gpu_transformer_method():
    from transformers import AutoTokenizer, RobertaForQuestionAnswering
    import torch

    tokenizer = AutoTokenizer.from_pretrained("deepset/roberta-base-squad2")
    model = RobertaForQuestionAnswering.from_pretrained("deepset/roberta-base-squad2")
    question, text = "Who was Jim Henson?", "Jim Henson was a nice puppet"
    inputs = tokenizer(question, text, return_tensors="pt")
    with torch.no_grad():
        outputs = model(**inputs)
    answer_start_index = outputs.start_logits.argmax()
    answer_end_index = outputs.end_logits.argmax()
    predict_answer_tokens = inputs.input_ids[0, answer_start_index: answer_end_index + 1]
    tokenizer.decode(predict_answer_tokens, skip_special_tokens=True)
    target_start_index = torch.tensor([14])
    target_end_index = torch.tensor([15])
    # Sleep added to make the task easier to track on the dashboard and nvidia-smi
    time.sleep(10)
    outputs = model(**inputs, start_positions=target_start_index, end_positions=target_end_index)
    loss = outputs.loss
    return loss


def load_dataset(spark: SparkSession) -> DataFrame:
    from pyspark.sql.functions import col
    # Local Pandas version of this occupies ~1.2GB RAM
    df = spark.range(1, 50_000_000)
    # calculate z = x + 2y + 1000
    df = df.withColumn("x", col("id") * 2)\
        .withColumn("y", col("id") + 200)\
        .withColumn("z", col("x") + 2 * col("y") + 1000)
    return df


def main():
    ray.init(address="ray://0.0.0.0:10001")
    print("connected to ray cluster")

    if TEST_TASK == "CPU":
        # Monte Carlo Pi estimation as a dummy load
        per_task_samples = 5_000_000
        task_count = 11
        results = [cpu_test_method.remote(per_task_samples) for _ in range(task_count)]
        total_samples = task_count * per_task_samples
        total_inside = sum(ray.get(results))
        pi = (total_inside * 4) / total_samples
        print(f"Pi estimate = {pi}\t Pi true = {math.pi}")

    elif TEST_TASK == "GPU":
        a = gpu_transformer_method.remote()
        b = ray.get(a)
        print(b)

    elif TEST_TASK == "DATASETS":
        import raydp
        spark = raydp.init_spark(
            app_name="example",
            num_executors=4,
            executor_cores=8,
            executor_memory="16GB"
        )
        dataset = load_dataset(spark)
        print()
        raydp.stop_spark()


if __name__ == '__main__':
    main()
