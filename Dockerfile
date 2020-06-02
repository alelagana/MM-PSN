FROM python:3.7

COPY requirements.txt /app/

RUN pip install -r /app/requirements.txt

COPY . /app/

CMD ["python", "/app/predict_psn_subgroup.py"]