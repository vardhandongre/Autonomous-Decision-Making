function [W1, W2] = rand_initialize_weights(Ninput, Nhidden, Noutput)
W1=rands(Nhidden,Ninput+1);
W2=rands(Noutput,Nhidden+1);
end
