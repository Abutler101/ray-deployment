import time
import ray


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


def main():
    ray.init(address="ray://0.0.0.0:10001")
    print("connected to ray cluster")
    a = gpu_transformer_method.remote()
    b = ray.get(a)
    print(b)


if __name__ == '__main__':
    main()
