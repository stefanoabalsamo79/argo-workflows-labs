# Argo Workflows Lab

## Intro
The aim of this lab is trying [`Argo Workflows`](https://argoproj.github.io/argo-workflows/). In this lab I spin up a simple architecture compose by:
* `producer`: container producing a file on a certain path (watched by the `watcher`)
* `watcher`: container watching a certain path, so anytime a new file is created it will trigger the `WorkflowTemplate`, leveraging the [`WorkflowEventBinding`](https://argoproj.github.io/argo-workflows/events/#submitting-a-workflow-from-a-workflow-template) mechanism
* [`Argo Workflow Template`](https://argoproj.github.io/argo-workflows/workflow-templates/)
  * `fileHandler`
  * `fileFilter`
  * `fileLoader`

## Prerequisites
1. [`docker`](https://www.docker.com/)
2. [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
3. [`kind`](https://kind.sigs.k8s.io/)
4. [`helm`](https://helm.sh/)
5. [`yq`](https://github.com/mikefarah/yq)
6. [`jq`](https://stedolan.github.io/jq/download/)

## Architecture diagram
![`image_001`](./diagrams_and_images/image_001.png)

## Repository structure
```text
├── Makefile
├── Readme.md
├── containers
│   ├── filehandler
│   ├── filefilter
│   ├── fileloader
│   ├── producer
│   └── watcher
├── deploy_charts
│   ├── Chart.yaml
│   ├── charts
│   │   ├── postgresdb
│   │   ├── producer
│   │   ├── watcher
│   │   └── workflow
│   ├── templates
│   └── values.yaml
├── diagrams_and_images
├── infra
└── utils
```

* `Makefile`: make file to automate all the architectural parts deployment
* `containers/filehandler`: application to take charge of the file came and move it in a tmp directory (part of the `WorkflowTemplate`)
* `containers/filefilter`: application to filter record according to a certain rule (part of the `WorkflowTemplate`)
* `containers/fileloader`: application to load the file content in the form of record in a postgres db table (part of the `WorkflowTemplate`)
* `containers/producer`: stand alone application to produce file every a certain interval (configurable)
* `containers/watcher`: stand alone application to monitor files coming through
* `deploy_charts`: directory where helm subcharts are found
* `infra`: folder containing `Argo Workflows` installation along with some other resources necessary to run the entire architecture
* `utils`: folder containing some shell scripts to handle the installation

## Main make file target
```bash
make all # deploy the whole stack
```

```bash
make clean_up # destroy the clusters
```

## Install
```bash
make all
```
---
***Notes:***
Once the installation is over let's portforward the the argo-server in order to access to its [`UI`](https://localhost:2746/)

---

## Main resources we have deployed

**`argo-server`, `postgres database`, `producer app`, `watcher app`, `workflow contoller`**
![`image_002`](./diagrams_and_images/image_002.png)

**persistent volume for db instance and `pv-1` in order containers can share filesystem**
![`image_003`](./diagrams_and_images/image_003.png)

**`WorkflowTemplate`**
![`image_004`](./diagrams_and_images/image_004.png)

**`WorkflowEventBinding`**
![`image_005`](./diagrams_and_images/image_005.png)

**the pictures below show the solution in action**
![`image_006`](./diagrams_and_images/image_006.png)
![`image_007`](./diagrams_and_images/image_007.png)
