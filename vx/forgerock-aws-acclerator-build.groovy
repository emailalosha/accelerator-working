@Library('SharedLibraryFROG@master') _

def buildDockerImages(image_name, image_tag, build_params=""){
    echo "${image_tag}"
    scContainerBuild {
        DOCKER_IMAGE_NAME = image_name
        DOCKER_IMAGE_VERSION = image_tag
        DOCKER_FILE = "Dockerfile"
        BUILD_PARAMS = build_params + " --no-cache"
        SIGN = true
    }
}

pipeline {
    agent { label "docker2x" }

    parameters {
        booleanParam(name: "BUILD_DS_BASE_IMAGES", defaultValue: false)
        booleanParam(name: "BUILD_AM_BASE_IMAGES", defaultValue: false)
        booleanParam(name: "BUILD_RS_CHILD_IMAGES", defaultValue: false)
        booleanParam(name: "BUILD_CS_CHILD_IMAGES", defaultValue: false)
        booleanParam(name: "BUILD_TS_CHILD_IMAGES", defaultValue: false)
        booleanParam(name: "BUILD_US_CHILD_IMAGES", defaultValue: false)
        booleanParam(name: "BUILD_AM_CHILD_IMAGES", defaultValue: false)
        string(defaultValue: 'scb-ubi', name: 'BUILD_BASE_IMAGES_TAG', trim: true)
        string(defaultValue: 'scb-ubi', name: 'BUILD_CHILD_IMAGES_TAG', trim: true)
    } //parameters

    environment {
        CI_REGISTRY_URL = "artifactory.global.standardchartered.com/ciam/forgerock"
        JAVA_BASE_CONTAINER_IMAGE = "${CI_REGISTRY_URL}/java-base"
        TOMCAT_BASE_CONTAINER_IMAGE = "${CI_REGISTRY_URL}/tomcat-base"
        AM_BASE_CONTAINER_IMAGE = "${CI_REGISTRY_URL}/am-base"
        DS_BASE_CONTAINER_IMAGE = "${CI_REGISTRY_URL}/ds-base"
        AM_CONTAINER_IMAGE = "${CI_REGISTRY_URL}/openam"
        CFGSTORE_CONTAINER_IMAGE = "${CI_REGISTRY_URL}/config-store"
        TOKENSTORE_CONTAINER_IMAGE = "${CI_REGISTRY_URL}/token-store"
        USERSTORE_CONTAINER_IMAGE = "${CI_REGISTRY_URL}/user-store"
        POLICYSTORE_CONTAINER_IMAGE = "${CI_REGISTRY_URL}/policy-store"
        REPLSERVER_CONTAINER_IMAGE = "${CI_REGISTRY_URL}/repl-server"
    }//environment


    stages {

        // stage('Verify User'){
        //     steps{
        //         script{
        //             validator.validateUser(env_name)
        //         }
        //     }
        // }
        stage('Build DS Base Docker Images') {
            when { expression { params.BUILD_DS_BASE_IMAGES } }
            agent { label "notary" }
            steps{
                script {
                    // BASE IMAGES
                    def JAVA_BASE_CONTAINER_IMAGE = "${JAVA_BASE_CONTAINER_IMAGE}"
                    def DS_BASE_CONTAINER_IMAGE = "${DS_BASE_CONTAINER_IMAGE}"

                    // TAG
                    def BUILD_BASE_IMAGES_TAG = "${BUILD_BASE_IMAGES_TAG}"
                    dir("${env.WORKSPACE}/base-images") {
                        dir("ds-base"){
                            buildDockerImages(DS_BASE_CONTAINER_IMAGE, BUILD_BASE_IMAGES_TAG, "--build-arg IMAGE_SRC=${JAVA_BASE_CONTAINER_IMAGE} --build-arg IMAGE_TAG=${BUILD_BASE_IMAGES_TAG}")
                        }
                    }

                }
            }
        }

        stage('Build AM Base Docker Images') {
            when { expression { params.BUILD_AM_BASE_IMAGES } }
            agent { label "notary" }
            steps{
                script {
                    // BASE IMAGES
                    def TOMCAT_BASE_CONTAINER_IMAGE = "${TOMCAT_BASE_CONTAINER_IMAGE}"
                    def AM_BASE_CONTAINER_IMAGE = "${AM_BASE_CONTAINER_IMAGE}"

                    // TAG
                    def BUILD_BASE_IMAGES_TAG = "${BUILD_BASE_IMAGES_TAG}"
                    dir("${env.WORKSPACE}/base-images") {
                        dir("am-base"){
                            buildDockerImages(AM_BASE_CONTAINER_IMAGE, BUILD_BASE_IMAGES_TAG, "--build-arg IMAGE_SRC=${TOMCAT_BASE_CONTAINER_IMAGE} --build-arg IMAGE_TAG=${BUILD_BASE_IMAGES_TAG}")
                        }
                    }

                }
            }
        }

        stage('Build RS Child Docker Images') {
            when { expression { params.BUILD_RS_CHILD_IMAGES } }
            agent { label "notary" }
            steps{
                script {
                    // BASE IMAGES
                    def DS_BASE_CONTAINER_IMAGE = "${DS_BASE_CONTAINER_IMAGE}"

                    // CHILD IMAGES
                    def REPLSERVER_CONTAINER_IMAGE = "${REPLSERVER_CONTAINER_IMAGE}"

                    // TAG
                    def BUILD_BASE_IMAGES_TAG = "${BUILD_BASE_IMAGES_TAG}"
                    def BUILD_CHILD_IMAGES_TAG = "${BUILD_CHILD_IMAGES_TAG}"

                    dir("${env.WORKSPACE}/child-images") {
                        dir("repl-server") {
                            buildDockerImages(REPLSERVER_CONTAINER_IMAGE, BUILD_CHILD_IMAGES_TAG, "--build-arg IMAGE_SRC=${DS_BASE_CONTAINER_IMAGE} --build-arg IMAGE_TAG=${BUILD_BASE_IMAGES_TAG}")
                        }
                    }

                }
            }
        }

        stage('Build CS Child Docker Images') {
            when { expression { params.BUILD_CS_CHILD_IMAGES } }
            agent { label "notary" }
            steps{
                script {
                    // BASE IMAGES
                    def DS_BASE_CONTAINER_IMAGE = "${DS_BASE_CONTAINER_IMAGE}"

                    // CHILD IMAGES
                    def CFGSTORE_CONTAINER_IMAGE = "${CFGSTORE_CONTAINER_IMAGE}"

                    // TAG
                    def BUILD_BASE_IMAGES_TAG = "${BUILD_BASE_IMAGES_TAG}"
                    def BUILD_CHILD_IMAGES_TAG = "${BUILD_CHILD_IMAGES_TAG}"

                    dir("${env.WORKSPACE}/child-images") {
                        dir("config-store") {
                            buildDockerImages(CFGSTORE_CONTAINER_IMAGE, BUILD_CHILD_IMAGES_TAG, "--build-arg IMAGE_SRC=${DS_BASE_CONTAINER_IMAGE} --build-arg IMAGE_TAG=${BUILD_BASE_IMAGES_TAG}")
                        }
                    }

                }
            }
        }

        stage('Build TS Child Docker Images') {
            when { expression { params.BUILD_TS_CHILD_IMAGES } }
            agent { label "notary" }
            steps{
                script {
                    // BASE IMAGES
                    def DS_BASE_CONTAINER_IMAGE = "${DS_BASE_CONTAINER_IMAGE}"

                    // CHILD IMAGES
                    def TOKENSTORE_CONTAINER_IMAGE = "${TOKENSTORE_CONTAINER_IMAGE}"

                    // TAG
                    def BUILD_BASE_IMAGES_TAG = "${BUILD_BASE_IMAGES_TAG}"
                    def BUILD_CHILD_IMAGES_TAG = "${BUILD_CHILD_IMAGES_TAG}"

                    dir("${env.WORKSPACE}/child-images") {
                        dir("token-store") {
                            buildDockerImages(TOKENSTORE_CONTAINER_IMAGE, BUILD_CHILD_IMAGES_TAG, "--build-arg IMAGE_SRC=${DS_BASE_CONTAINER_IMAGE} --build-arg IMAGE_TAG=${BUILD_BASE_IMAGES_TAG}")
                        }
                    }

                }
            }
        }

        stage('Build US Child Docker Images') {
            when { expression { params.BUILD_US_CHILD_IMAGES } }
            agent { label "notary" }
            steps{
                script {
                    // BASE IMAGES
                    def DS_BASE_CONTAINER_IMAGE = "${DS_BASE_CONTAINER_IMAGE}"

                    // CHILD IMAGES
                    def USERSTORE_CONTAINER_IMAGE = "${USERSTORE_CONTAINER_IMAGE}"

                    // TAG
                    def BUILD_BASE_IMAGES_TAG = "${BUILD_BASE_IMAGES_TAG}"
                    def BUILD_CHILD_IMAGES_TAG = "${BUILD_CHILD_IMAGES_TAG}"

                    dir("${env.WORKSPACE}/child-images") {
                        dir("user-store") {
                            buildDockerImages(USERSTORE_CONTAINER_IMAGE, BUILD_CHILD_IMAGES_TAG, "--build-arg IMAGE_SRC=${DS_BASE_CONTAINER_IMAGE} --build-arg IMAGE_TAG=${BUILD_BASE_IMAGES_TAG}")
                        }
                    }

                }
            }
        }

        stage('Build AM Child Docker Images') {
            when { expression { params.BUILD_AM_CHILD_IMAGES } }
            agent { label "notary" }
            steps{
                script {
                    // BASE IMAGES
                    def AM_BASE_CONTAINER_IMAGE = "${AM_BASE_CONTAINER_IMAGE}"

                    // CHILD IMAGES
                    def AM_CONTAINER_IMAGE = "${AM_CONTAINER_IMAGE}"

                    // TAG
                    def BUILD_BASE_IMAGES_TAG = "${BUILD_BASE_IMAGES_TAG}"
                    def BUILD_CHILD_IMAGES_TAG = "${BUILD_CHILD_IMAGES_TAG}"

                    dir("${env.WORKSPACE}/child-images") {
                        dir("access-manager") {
                            buildDockerImages(AM_CONTAINER_IMAGE, BUILD_CHILD_IMAGES_TAG, "--build-arg IMAGE_SRC=${AM_BASE_CONTAINER_IMAGE} --build-arg IMAGE_TAG=${BUILD_BASE_IMAGES_TAG}")
                        }
                    }

                }
            }
        }

    }//stages-end

}//pipeline-end