package main

import (
	"github.com/aws/aws-lambda-go/lambda"
)

type Request struct {
	Body string `json:"body"`
}

type Response struct {
	StatusCode      int    `json:"statusCode"`
	Body            string `json:"body"`
}


func handler(request Request) (Response, error) {
	response := Response{
		StatusCode:      200,
		Body:            "",
	}
	return response, nil
}

func main () {
	lambda.Start(handler)
}