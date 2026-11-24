// Тот же конвейер: lint и test в контейнере python:3.13
pipeline {
    agent {
        docker { image 'python:3.13' }   // выполнять стадии внутри контейнера из этого образа
    }
    options {
        timeout(time: 10, unit: 'MINUTES')   // зависшая сборка не держит агента вечно
    }
    environment {
        PIP_CACHE_DIR = '.cache/pip'   // у пользователя контейнера нет домашней папки, кэш кладём в проект
    }
    stages {
        stage('Lint') {
            steps {
                // venv в рабочем каталоге: у пользователя контейнера нет прав писать в /
                sh '''
                    python -m venv .venv
                    . .venv/bin/activate
                    pip install -r requirements-dev.txt
                    make lint
                '''
            }
        }
        stage('Test') {
            steps {
                sh 'make test'
            }
        }
    }
}
