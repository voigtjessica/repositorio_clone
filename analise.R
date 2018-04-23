
dados <- read.csv("dados.csv")
lm(idade ~ sexo + reprovacoes, data = dados)
plot(density(dados$idade))
