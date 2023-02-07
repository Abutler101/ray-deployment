import math
import time
import ray

TEST_TASK = "GPU"  # Possible values: GPU, CPU, DATASETS


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


@ray.remote
def load_dataset():
    ...


def main():
    ray.init(address="ray://0.0.0.0:10001")
    print("connected to ray cluster")

    if TEST_TASK == "CPU":
        per_task_samples = 10_000
        task_count = 4
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
        ...


if __name__ == '__main__':
    main()
