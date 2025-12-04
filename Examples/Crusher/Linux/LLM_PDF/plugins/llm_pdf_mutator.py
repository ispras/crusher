from openai import OpenAI
from pypdf import PdfReader
from pypdf.errors import PdfReadError
import os, sys
import tempfile


def initialization():
    info_mut_alg = {
        "mut_name": "llm_pdf_mutator",
        "class": "LlmPdfMutator",
        "method": "perform_mutation",
    }
    return info_mut_alg


def read_file(path):
    text = "```\n"
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        text += f.read()

    text += "\n```\n\n"
    return text


def make_prompt(data):
    prompt = "For the PDF format, the following is the dictionary for the format:\n\n"
    prompt += read_file(os.path.dirname(__file__) + "/pdf_fuzzer.dict")

    prompt += "And the following is the example file to be mutated:\n\n```\n"
    prompt += data.decode("utf-8")
    prompt += "\n```\n\n"

    prompt += "Please mutate this example file of the PDF format such that it contains text, different fonts and images, and the mutated PDF file is:\n"

    return prompt


def make_correction_prompt(data, new_pdf):
    prompt = "For the PDF format, the following is the dictionary for the format:\n\n"
    prompt += read_file(os.path.dirname(__file__) + "/pdf_fuzzer.dict")

    prompt += (
        "And the following is the source example file to be mutated:\n\n```\n"
    )
    prompt += data.decode("utf-8")
    prompt += "\n```\n\n"

    prompt += "And the following is the mutated PDF file that is not a valid PDF:\n\n```\n"
    prompt += new_pdf
    prompt += "\n```\n\n"

    prompt += "Please correct mistakes in this mutated example file of the PDF format such that it is a valid PDF, and the corrected PDF file is:\n"

    return prompt


def extract_pdf(response):
    lines = response.split("\n")
    i = 0
    while i < len(lines):
        if lines[i].startswith("```"):
            pdf_lines = []
            i += 1
            while i < len(lines) and not lines[i].startswith("```"):
                pdf_lines.append(lines[i])
                i += 1
            return "\n".join(pdf_lines)
        else:
            i += 1


def check_pdf(pdf):
    f = tempfile.NamedTemporaryFile(mode='w')
    f.write(pdf)
    f.flush()
    try:
        PdfReader(f.name, strict=True)
    except PdfReadError as e:
        f.close()
        print(f"Invalid PDF file: {str(e)}")
        return False
    else:
        f.close()
        return True


class LlmPdfMutator:
    def __init__(self, init=None):
        model = "openai/gpt-4o-mini"
        temperature = 0.7
        n = 1
        max_tokens = 3000
        if init is not None:
            self.init = True
        else:
            self.init = False
        self.client = OpenAI(
            api_key=os.getenv("ISP_LLM_API_KEY"),  # ваш ключ в сервисе после регистрации
            base_url=os.getenv("ISP_LLM_API_URL"), # адрес сервиса OpenAI
        )
        self.model = model
        self.temperature = temperature
        self.n = n
        self.max_tokens = max_tokens
        self.freq = 500
        self.make_valid = False

    def perform_mutation(self, data=None):
        if self.init:
            self.init = False
            return 42
        if self.freq != 0:
            self.freq -= 1
            return data
        self.freq = 500
        prompt = make_prompt(data)
        print(prompt)

        messages = []
        # messages.append({"role": "system", "content": system_text})
        messages.append({"role": "user", "content": prompt})

        response_big = self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            temperature=self.temperature,
            n=self.n,
            max_tokens=self.max_tokens,
        )

        # print("Response BIG:",response_big)
        response = response_big.choices[0].message.content

        new_pdf = extract_pdf(response)
        valid = check_pdf(new_pdf)
        cnt = 0
        while self.make_valid and not valid and not cnt == 5:
            prompt = make_correction_prompt(data, new_pdf)
            # messages = []
            # messages.append({"role": "system", "content": system_text})
            messages.append({"role": "user", "content": prompt})
            response_big = self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                temperature=self.temperature,
                n=self.n,
                max_tokens=self.max_tokens,
            )

            # print("Response BIG:",response_big)
            response = response_big.choices[0].message.content
            print("Response:", response)

            new_pdf = extract_pdf(response)
            valid = check_pdf(new_pdf)
            cnt += 1
        new_pdf = bytearray(new_pdf, "utf-8")
        return new_pdf
