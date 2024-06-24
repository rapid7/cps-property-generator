pipeline {

    agent {
        kubernetes(
            k8sAgent(
                name: 'ruby',
                rubyRuntime: "3.3",
                idleMinutes: params.POD_IDLE_MINUTES
            )
        )
    }

    options {
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '20')
        ansiColor('xterm')
        timestamps()
        timeout(360) // Mins
    }

    parameters {
        string(name: 'POD_IDLE_MINUTES', defaultValue: '0', description: 'Number of minutes pod will stay idle post build')
    }

    stages {
        stage('Hello') {
            steps {
                echo 'Hello World'
            }
        }
    } // End of stages

} // End of pipeline
