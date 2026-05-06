zed board
테트리스

정사각형이 속도에 따라 내려온다
parameter FALL_SPEED = 27'd3_300_000;를 변경하면 내려오는 속도를 조절할 수 있다
FSM을 이용

parameter BOX_X = 375,   // 시작 x
           BOTTOM    = 480 - 50,   // 시작 y
           BOX_SIZE = 30;
Box X와 Bottom, box_size를 이용 -> 정사각형의 위치와 크기를 변경가능하다