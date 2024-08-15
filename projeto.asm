#
# IAC 2023/2024 k-means
# 
# Grupo: 67
# Campus: Alameda
#
# Autores:
# 109245, Jose Araujo
# 109264, Francisco Mendonca
# 109260, Ana Santos
#
# Tecnico/ULisboa


# ALGUMA INFORMACAO ADICIONAL PARA CADA GRUPO:
# - A "LED matrix" deve ter um tamanho de 32 x 32
# - O input e' definido na seccao .data. 
# - Abaixo propomos alguns inputs possiveis. Para usar um dos inputs propostos, basta descomentar 
#   esse e comentar os restantes.
# - Encorajamos cada grupo a inventar e experimentar outros inputs.
# - Os vetores points e centroids estao na forma x0, y0, x1, y1, ...


# Variaveis em memoria
.data

#Input A - linha inclinada
#n_points:    .word 9
#points:      .word 0,0, 1,1, 2,2, 3,3, 4,4, 5,5, 6,6, 7,7 8,8

#Input B - Cruz
#n_points:    .word 5
#points:     .word 4,2, 5,1, 5,2, 5,3 6,2

#Input C
#n_points:    .word 23
#points: .word 0,0, 0,1, 0,2, 1,0, 1,1, 1,2, 1,3, 2,0, 2,1, 5,3, 6,2, 6,3, 6,4, 7,2, 7,3, 6,8, 6,9, 7,8, 8,7, 8,8, 8,9, 9,7, 9,8

#Input D
n_points:    .word 30
points:      .word 16, 1, 17, 2, 18, 6, 20, 3, 21, 1, 17, 4, 21, 7, 16, 4, 21, 6, 19, 6, 4, 24, 6, 24, 8, 23, 6, 26, 6, 26, 6, 23, 8, 25, 7, 26, 7, 20, 4, 21, 4, 10, 2, 10, 3, 11, 2, 12, 4, 13, 4, 9, 4, 9, 3, 8, 0, 10, 4, 10



# Valores de centroids e k a usar na 1a parte do projeto:
#centroids:   .word 0,0
#k:           .word 1

# Valores de centroids, k e L a usar na 2a parte do prejeto:
centroids:   .word 0,0, 10,0, 0,10
k:           .word 3
L:           .word 10

# Abaixo devem ser declarados o vetor clusters (2a parte) e outras estruturas de dados
# que o grupo considere necessarias para a solucao:
clusters: .word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0




#Definicoes de cores a usar no projeto 

colors:      .word 0xff0000, 0x00ff00, 0x0000ff  # Cores dos pontos do cluster 0, 1, 2, etc.

.equ         black      0
.equ         white      0xffffff



# Codigo
 
.text
    # Chama funcao principal da 1a parte do projeto
    # jal mainSingleCluster

    # Chama funcao principal da 2a parte do projeto
    jal mainKMeans
    
    # Termina o programa (chamando chamada sistema)
    li a7, 10
    ecall


### printPoint
# Pinta o ponto (x,y) na LED matrix com a cor passada por argumento
# Nota: a implementacao desta funcao ja' e' fornecida pelos docentes
# E' uma funcao auxiliar que deve ser chamada pelas funcoes seguintes que pintam a LED matrix.
# Argumentos:
# a0: x
# a1: y
# a2: cor

printPoint:
    li a3, LED_MATRIX_0_HEIGHT
    sub a1, a3, a1
    addi a1, a1, -1
    li a3, LED_MATRIX_0_WIDTH
    mul a3, a3, a1
    add a3, a3, a0
    slli a3, a3, 2
    li a0, LED_MATRIX_0_BASE
    add a3, a3, a0   # addr
    sw a2, 0(a3)
    jr ra

    
### cleanScreen
# Limpa todos os pontos do ecra'
# Argumentos: nenhum
# Retorno: nenhum

cleanScreen:  
    addi sp, sp, -4 # aloca espaco na pilha
    sw ra, 0(sp) # salva o ra na pilha
    li x7, 32 # coordenada maxima do led
    li a2, white
    li x5, 0 # i = 0
    LOOPI:        
        li x6, 0 # j = 0
        bge x5, x7, ENDI # While i < 32
    LOOPJ: 
        bge x6, x7, ENDJ # While j < 32
        mv a0, x5 # x = i
        mv a1, x6 # y = j
        jal printPoint
        addi x6, x6, 1
        j LOOPJ
    ENDJ:
        addi x5, x5, 1
        j LOOPI
    ENDI:
    lw ra, 0(sp) # recupera o ra
    addi sp, sp, 4 # da free do espaco alocado
    jr ra

  
### colorSelect
# Seleciona a cor correspondente a cada cluster de acordo com o vetor das cores
# Argumentos: 
# a3: cluster index
# Retorno: 
# a2: cor

colorSelect:
    la s5, colors
    #OPTIMIZATION Ao inve's de utilizar um registo e uma instrucao extra (li) que guardava 
    # o valor 4 e depois multiplicar o a3 por 4, utilizo o slli
    slli a3, a3, 2
    add s5, s5, a3 # desloca para a cor certa
    lw a2, 0(s5) # carrega a cor correspondente ao cluster
    jr ra


    
### printClusters
# Pinta os agrupamentos na LED matrix com a cor correspondente.
# Argumentos: nenhum
# Retorno: nenhum  

printClusters:
    addi sp, sp, -4
    sw ra, 0(sp)
    li t0, 1 # i = 1
    lw s2, n_points # s2 = numero de pontos
    addi s2,s2, 1 # adiciono +1 para o loop funcionar
    lw t2, k # t2 = k
    beq t2, t0, ClusterSingle # se o k for igual a 1
    bgt t2, t0, ClusterMultiple # se o k for maior que 1
    ClusterSingle:
        la s3, points # s3 = points
        loopCS:
            lw t2, 0(s3) 
            lw t3, 4(s3) 
            mv a0, t2
            mv a1, t3
            li a2, 0xff0000 
            jal printPoint
            addi s3, s3, 8 # points anda 8 bytes para a frente
            addi t0, t0 , 1
            blt t0, s2, loopCS # while i < = n_points + 1 (i inicializado a 1)
        j ENDClusters
    ClusterMultiple:
        la s3, points
        la s4, clusters
        loopCM:
            lw t2, 0(s3) 
            lw t3, 4(s3) 
            lw a3, 0(s4) 
            mv a0, t2
            mv a1, t3
            jal colorSelect # atribui a cor a a2 consoante o indice do cluster
            jal printPoint
            addi s3, s3, 8 # points anda 8 bytes para a frente
            addi s4, s4, 4 # clusters anda 4 bytes para a frente
            addi t0, t0 , 1
            blt t0, s2, loopCM # while i < = n_points + 1 (i inicializado a 1)
        j ENDClusters
        ENDClusters:
            lw ra, 0(sp)
            addi sp, sp, 4
            jr ra


### printCentroids
# Pinta os centroides na LED matrix
# Nota: deve ser usada a cor preta (black) para todos os centroides
# Argumentos: nenhum
# Retorno: nenhum

printCentroids:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, centroids
    lw t1, k
    li t2, 0
    la a2, black # define a cor preta
    LOOPCENTROID:
        beq t1,t2,ENDCENTROID
        lw a0,0(t0) # x
        lw a1,4(t0) # y
        jal printPoint
        addi t2, t2, 1
        addi t0, t0, 8 # centroids anda 8 bytes para a frente
        j LOOPCENTROID
    ENDCENTROID:
        lw ra, 0(sp)
        addi sp, sp, 4
        jr ra


### calculateCentroisHelper
# Calcula os centroids quando k>1
# Argumentos: nenhum
# Retorno: nenhum

calculateCentroidsHelper:
    addi sp, sp, -4
    sw ra, 0(sp)
    li t0, 0 # i = 0
    lw t2, n_points 
    la t4, centroids 
    lw t3, k
    la s5, clusters 
    li s8,0 # 2o counter 
    
    LOOPK:
        li t1, 0 # j = 0
        li s2, 0 # somaX = 0
        li s3, 0 # somaY = 0
        li s4, 0 # 1o counter
        la s5, clusters 
        la t5, points 
        bge t0, t3, ENDK # while i < k
        
    LOOPCLUSTERS:
        bge t1, t2, ENDCLUSTERS # while j < n_points
        lw t6, 0(t5) # x
        lw s0, 4(t5) # y
        lw s1, 0(s5) # indice do cluster
        addi s5,s5,4 
        addi t5,t5,8 
        addi t1, t1, 1 #j++
        bne s1, t0, LOOPCLUSTERS # Se o cluster na'o for igual ao k continua o loop
        add s2, s2, t6 # somaX += x
        add s3, s3, s0 # somaY += y
        addi s4, s4, 1 # counter++ 
        j LOOPCLUSTERS
        
    ENDCLUSTERS:
        addi t4,t4,8 
        addi t0,t0,1 # i++
        beqz s4, NoPoints # verifica se existem ou na'o pontos no cluster k
        addi t4,t4,-8 
        div s2,s2,s4 # somaX // n pontos do cluster k
        div s3,s3, s4 # somaY // n pontos do cluster k
        lw s6, 0(t4)
        lw s7, 4(t4)
        beq s6, s2, Xigual # verifica se o centroid anterior vai ser igual ao novo centroid
        j NoEqualCentroids
        Xigual:
            beq s7,s3, Yigual
            j NoEqualCentroids
        Yigual:
            addi s8, s8, 1  
        NoEqualCentroids:   
        sw s2, 0(t4) # guardar o X no centroid k
        sw s3, 4(t4) # guardar o Y no centroid k
        addi t4,t4,8 # andar um centroid para a frente
        j LOOPK 
           
    ENDK:
    beq s8, t3, ChangeS10 # Se o 2o counter atinge o valor de k significa que nao houve alteracao nos centroids
    j ENDKOFICIAL
    ChangeS10:
        li s10,1 # s10 fica igual a 1 para na funcao mainKmeans o loop terminar
        
    ENDKOFICIAL:  
    lw ra, 0(sp) 
    addi sp, sp, 4
    jr ra
    
    NoPoints:
    addi s8, s8, 1  # Se nao existirem pontos no cluster significa que o centroid atual tambem nao se alterou
    j LOOPK


### calculateCentroids
# Calcula os k centroides, a partir da distribuicao atual de pontos associados a cada agrupamento (cluster)
# Argumentos: nenhum
# Retorno: nenhum   
 
calculateCentroids:
    addi sp, sp, -4
    sw ra, 0(sp)
    li t0, 1 # i = 1
    lw t1, n_points # t1 = numero de pontos
    addi t1,t1, 1 # +1 para o loop funcionar
    lw t2, k 
    beq t0, t2, singleCluster # se o k for igual a 1
    jal calculateCentroidsHelper 
    j end
    
    singleCluster:
        la t2, points 
        li t3, 0 # soma do x inicializada a 0
        li t4, 0 # soma do y inicializada a 0
        loopSC:
            lw t5, 0(t2)
            lw t6, 4(t2) 
            add t3, t3, t5 # somaX+=x
            add t4, t4, t6 # somaY+=y
            addi t2, t2, 8 # points anda 8 bytes para a frente
            addi t0, t0 , 1 # i++
            bleu t0, t1, loopSC # while i < = n_points + 1 (i inicializado a 1)
            
            addi t1, t1, -1 # n_points volta ao numero inicial 
            
            div t3, t3, t1 
            div t4, t4, t1 
            
            la t5, centroids 
            sw t3, 0(t5) 
            sw t4, 4(t5)
    end:
        lw ra, 0(sp)
        addi sp, sp, 4
        jr ra


### mainSingleCluster
# Funcao principal da 1a parte do projeto.
# Argumentos: nenhum
# Retorno: nenhum

mainSingleCluster:
    addi sp, sp, -4
    sw ra, 0(sp)

    #1. Coloca k = 1 (caso nao esteja a 1)
	li t1, 1
	la t2, k	
	bne t1, t2, defineOne # Se k for diferente de 1
	j ExitOne
	defineOne:
		sw t1, 0(t2) # Mete k = 1
	ExitOne:
    
    #2. cleanScreen
    jal cleanScreen

    #3. printClusters
    jal printClusters

    #4. calculateCentroids
    jal calculateCentroids
    
    #5. printCentroids
    jal printCentroids

    #6. Termina
    lw ra, 0(sp)
    addi sp, sp, 4
    
    jr ra


### manhattanDistance
# Calcula a distancia de Manhattan entre (x0,y0) e (x1,y1)
# Argumentos:
# a0, a1: x0, y0
# a2, a3: x1, y1
# Retorno:
# a0: distance

manhattanDistance:
    blt a0, a2, sub1 # verifica se o x0 < x1
    sub t0, a0, a2 # se nao for, x0-x1
    j y
    sub1:
        sub t0, a2, a0 # se for, x1-x0
    y:
        blt a1, a3,  sub2 # verifica se o y0 < y1
        sub t1, a1, a3 # se nao for, y0-y1
        j saida
    sub2: 
        sub t1, a3, a1 # se for, y1-y0
    saida:
        add a0, t0, t1 # adiciona os valores x + y
    jr ra


### nearestCluster
# Determina o centroide mais perto de um dado ponto (x,y).
# Argumentos:
# a0, a1: (x, y) point
# Retorno:
# a0: cluster index

nearestCluster:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    # t1 vai ser a variavel que vai conter a menor manhattan distance
    li t1, 31 # Distancia maxima
    mv t2, a0 # Guarda o valor do a0 que vai ser modificado na funcao manhattanDistance
    lw t3, k
    la t4, centroids
    li t5, 0 # i = 0
    li t6, 0 # Indice do cluster
    loopNearestCluster:
        beq t5,t3, ExitNearestCluster # Se o i = k, termina o loop
        lw a2,0(t4) # Guarda o x do centroide no a2
        lw a3,4(t4) # Guarda o x do centroide no a3
        addi t4, t4, 8 # Salta para o proximo centroide
        
        addi sp, sp, -4
        sw t1, 0(sp) 
        jal manhattanDistance
        lw t1, 0(sp)
        addi sp, sp, 4
         
        blt a0, t1, newNearestCluster # Se a0 < t1 muda o nearest cluster
        addi t5, t5, 1 #i++
        j keepCluster # De outro modo, mantem o cluster
        newNearestCluster:
            addi t5, t5, 1 #i++
            mv t1, a0 # atualiza a distancia minima
            mv t6, t5 # atualiza o cluster atual
            mv a0, t2 # Restitui o a0
            j loopNearestCluster
        keepCluster:
            mv a0, t2
            j loopNearestCluster
    ExitNearestCluster:
        mv a0, t6 # Mete o numero do cluster no a0 para o valor de retorno
        addi a0, a0, -1 # Retira 1 pois consideramos o primeiro cluster como o 0
        
        lw ra, 0(sp)
        addi sp, sp, 4
        jr ra


### initializeCentroids
# Inicializa os valores dos centroids de forma pseudo-aleatoria
# Argumentos: nenhum
# Retorno: nenhum

initializeCentroids:
    addi sp, sp, -4
    sw ra, 0(sp)
    la a2, centroids
    lw a3, k
    add a3, a3, a3
    li t0, 32 # i = 31
    li t1, 101 # multiplicador, um numero primo para melhorar a qualidade do gerador de numeros
    li t2, 199 # incremento, um numero primo para melhorar a qualidade do gerador de numeros
    li t4, 0
    li a7, 30 # Usa a system call que coloca no a0 quantos milisegundos passaram deste 1 Janeiro de 1970
    ecall
    addi, t3, a0, 0
    beqz a3, ENDini
    
    LOOPini:
        remu t3, t3, t0 # calcula o resto da divisao por 32 para resultar num valor de 0 a 31
        sw t3, 0(a2) # atualiza o valor com o valor calculado pseudo-aleatoriamente
        mul t3, t3, t1 # multiplica o valor anterior por um numero primo
        add t3, t3, t2 # adiciona outro numero primo
        addi a2, a2, 4 # desloca a lista dos centroids 4 bytes para a frente
        addi t4, t4, 1
        bne a3, t4, LOOPini
        
    ENDini:
        lw ra, 0(sp)
        addi sp, sp , 4
        jr ra


### atualizeClusters
# Atualiza os clusters de acordo com o nearestCentroid de cada ponto
# Argumentos: nenhum
# Retorno: nenhum

atualizeClusters:
    addi sp, sp, -4
    sw ra, 0(sp)
    li t0, 0 # i = 0
    lw t1, n_points # t1 = n_points
    la a4, clusters
    la a5, points
    
    LOOPCLUSTERSI:
        bge t0,t1, ENDCLUSTERSI # While i <= n_points
        lw t5,0(a5) # Guarda o x do ponto em a0
        mv a0,t5
        lw t5,4(a5) # Guarda o y do ponto em a1
        mv a1,t5
        addi a5, a5, 8 # Anda para o proximo ponto
        
        addi sp, sp, -8
        sw t0, 0(sp)
        sw t1, 4(sp)
        jal nearestCluster
        lw t0, 0(sp)
        lw t1, 4(sp)
        addi sp, sp, 8
        
        sw a0, 0(a4) # Modifica o cluster do ponto 
        addi a4, a4 , 4 # Anda para o proximo cluster
        addi t0,t0,1 # i++
        j LOOPCLUSTERSI
        
    ENDCLUSTERSI:
        lw ra, 0(sp)
        addi sp, sp , 4
        jr ra


### mainKMeans
# Executa o algoritmo k-means.
# Argumentos: nenhum
# Retorno: nenhum

mainKMeans:  
   addi sp, sp, -8 # Reserva espac'o na pilha para salvar ra e s0
   sw ra, 4(sp)        
   sw s10, 0(sp) 
             
   lw s10, L # L iteracoes
   
   #1. Inicializacao dos centroids
   jal initializeCentroids
   
MAINKMEANS:
    beqz s10, ENDKMEANS # While L != 0
    
    #2. cleanScren
    # Limpa o ecra' no inicio de cada iteracao
    jal cleanScreen
    
    #3. atualizeClusters
    jal atualizeClusters
   
    #4. printClusters
    jal printClusters
   
    #5. calculateCentroids
    jal calculateCentroids
   
    #6. printCentroids
    jal printCentroids
   
    addi s10, s10, -1    
    j MAINKMEANS

ENDKMEANS:
    lw s0, 0(sp)
    lw ra, 4(sp)        
    addi sp, sp, 8      
    jr ra
