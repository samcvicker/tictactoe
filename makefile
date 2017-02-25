tictactoe.smc: tictactoe.asm tictactoe.link
	../wla-65816 -vo tictactoe.asm tictactoe.obj
	../wlalink -vr tictactoe.link tictactoe.smc
	git add *
	git commit -m "auto-commit from makefile"
	git push
