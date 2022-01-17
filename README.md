# BBP IoT demo environment

1. Create `env.sh` containing your Aiven API token

```
export TF_VAR_aiven_api_token=<your api key>
```

2. Create infrastructure

```
$ source env.sh
$ terraform init
$ terraform plan
$ terraform apply
```

3. Download Kafka credentials
```
$ mkdir creds
$ cd creds
$ avn service user-creds-download bbp-demo-kafka --username avnadmin
```

4. Create Python 3 virtualenv and install dependencies

```
$ python3 -m -venv venv
$ source venv/bin/activate
$ pip install -r requirements.txt
```

5. Publish messages to Kafka topic using script, e.g.

```
$ scripts/produce_data.py bbp-demo-kafka-dbeech-demo-94df.aivencloud.com:13225 m3
```

> Note: the second argument can be either "m3" or "influx" depending on which topic you wish to direct the dummy data to.