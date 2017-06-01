#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>
#define D 1000

#define re -0.5
#define im 0.45
#define scale 1.5

__device__ int julia( float x, float y){
	float xj = scale * (float)(D/2 - x)/(D/2);
	float yj = scale * (float)(D/2 - y)/(D/2);

	for( int i=0; i<200; ++i){
		float a = xj;
		float b = yj;
		xj = a*a-b*b+re;
		yj = 2*a*b+im;
	}
	if( xj*xj + yj*yj < 4)
		return 1;
	else
		return 0;
}

__global__ void generuj( int * picture ){
	//sprawdz czy pkt nalezy do zbioru julii
	int i = blockIdx.x;
	int j = threadIdx.x;

	
	if( julia(i, j ) )
		picture[ i * D + j ] = 1;
	else
		picture[ i * D + j ] = 0;
	
}



int main()
{
	FILE *fp;
	if ((fp=fopen("obraz.pbm", "w"))==NULL) {
		printf ("Nie mogê otworzyæ pliku test.txt do zapisu!\n");
		exit(1);
    }

	fprintf( fp, "P1\n%d %d\n", D, D);

	//deklarujê tablicê na karcie graficznej
	int * dev_obraz;
	cudaMalloc( &dev_obraz, sizeof(int) * D *D  );
	
	printf("udalo sie zaalokowac na karcie graficznej\n\n\n");

	//generacja obrazu
	generuj <<< D, D >>> ( dev_obraz );
	printf("funkcja zakonczyla dzialanie\n\n\n");

	//skopiowanie obrazu z karty graficznej

	int ** obraz;

	obraz = (int **) malloc( sizeof(int*)*D );
	
	
	
	for( int i=0; i<D; ++i){
		obraz[i] = (int *) malloc( sizeof(int)*D );
		cudaMemcpy( obraz[i], dev_obraz+i*D, sizeof(int)*D, cudaMemcpyDeviceToHost);
	}
	

	printf("skopiowano z karty graficznej\n\n\n");

	//zapisanie obrazu w formie pbm (P1)
	for(int i=0; i<D; ++i){
		for(int j=0; j<D; ++j)
			fprintf(fp, "%d", obraz[i][j]);
		fprintf(fp, "\n");
	}

	fclose(fp);

	return 0;
}
