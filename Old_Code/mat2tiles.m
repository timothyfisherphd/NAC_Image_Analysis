function outCell=mat2tiles(inArray,varargin)

tileSizes=[varargin{:}];
N=length(tileSizes);
Nmax=ndims(inArray);
if N<Nmax
   
    tileSizes=[tileSizes,inf(1,Nmax-N)];
    
    
elseif N>Nmax    
    
    tileSizes=tileSizes(1:Nmax);
    
end
N=Nmax;
C=cell(1,N);
for ii=1:N %loop over the dimensions
    
 dim=size(inArray,ii);
 T=min(dim, tileSizes(ii));
 
 if T~=floor(T) || T<=0
     error 'Tile dimension must be a strictly positive integer or Inf'
 end
 
 nn=( dim / T );
   nnf=floor(nn);
 
 resid=[];
 if nnf~=nn 
    nn=nnf;
    resid=dim-T*nn;
 end
 
 C{ii}=[ones(1,nn)*T,resid];    
    
    
end
outCell=mat2cell(inArray,C{:});